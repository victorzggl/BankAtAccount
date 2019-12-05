use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_InsertCustPayment] @cust_id int, @cust_payment_type_id int, @payment_date datetime = null, @payment_amount decimal(18,2), @settlement_date date = null, @tran_num varchar(100) = null, @inserted_by varchar(100) = null, @cust_payment_id int = null output, @error varchar(500) = null output, @bank_contract_id int = null
as 

/*
declare @cust_payment_id int, @error varchar(500)

exec cds_InsertCustPayment @cust_id = 0, @cust_payment_type_id = 2, @payment_date = '2019-02-19', @payment_amount = 100, @settlement_date = null, @tran_num = 'ABC123456789', @cust_payment_id = @cust_payment_id output, @error = @error output

select @cust_payment_id [cust_payment_id], @error [error]
*/

select @cust_payment_id = null, @error = ''

declare @cust_payment_type varchar(50) = (select code from cust_payment_type where cust_payment_type_id = @cust_payment_type_id),
		@bank_id int,
		@invoice_balance_due decimal(18,2)

if @inserted_by is null
	set @inserted_by = 'SYSTEM'

if @cust_payment_type = 'INTERNAL_BANK_TRANSACTION' and @inserted_by <> 'SYSTEM'
	select @invoice_balance_due = sum(ai.total_amount - isnull(ap.payment_amount,0))
	from account_invoice ai
	left join account_invoice_payment_status aips on ai.account_invoice_payment_status_id = aips.account_invoice_payment_status_id
	left join
		(select ap.account_invoice_id, sum(ap.payment_amount) [payment_amount]
		from account_payment ap
		join cust_payment cp on ap.cust_payment_id = cp.cust_payment_id
		join cust_payment_status cps on cp.cust_payment_status_id = cps.cust_payment_status_id
		where cp.cust_id = @cust_id
		and cps.code = 'PAID'
		group by ap.account_invoice_id) ap on ai.account_invoice_id = ap.account_invoice_id
	where ai.cust_id = @cust_id
	and isnull(aips.code,'') not in ('PAID','CANCEL_REBILL')
	and ai.total_amount <> isnull(ap.payment_amount,0)
	and ai.due_date < getdate()

if not exists (select * from cust where cust_id = @cust_id)
	set @error += 'Customer ID is invalid or missing; '

if @cust_payment_type is null
	set @error += 'Customer payment type is invalid or missing; '

if @payment_amount is null or @payment_amount <= 0
	set @error += 'Payment amount is invalid or missing; '

if exists (select * from cust_payment where tran_num = @tran_num)
	set @error += 'Transaction number has already been entered; '

if @cust_payment_type = 'INTERNAL_BANK_TRANSACTION'
begin
	if not exists(select 1 from bank_contract bc where bank_contract_id = @bank_contract_id)
		set @error += 'A bank_contract_id is required for Internal Bank Transaction; '

	set  @bank_id = (select top (1) bank_id from dbo.cds_fn_GetActiveBankContract (null, @cust_id, @bank_contract_id))

	if @bank_id is null
		set @error += 'An ACTIVE bank account is required for Internal Bank Transaction; '

	if @payment_amount > isnull(@invoice_balance_due,0) and @inserted_by <> 'SYSTEM'
		set @error += 'Payment amount cannot be greater than invoice balance due; '
end

if @cust_payment_type in ('CUSTOMER_BANK_TRANSACTION','CREDIT_CARD') and @tran_num is null
	set @error += 'Tran number is required; '

if @cust_payment_type in ('CUSTOMER_BANK_TRANSACTION','CREDIT_CARD') and @payment_date is null
	set @error += 'Payment date is required; '

if @error = ''
begin
	if @cust_payment_type = 'INTERNAL_BANK_TRANSACTION'
	begin
		declare @bank_transaction_type_id int = (select bank_transaction_type_id from bank_transaction_type where code = 'WITHDRAW'),
				@bank_transaction_id int

		exec cds_InsertBankTransaction @bank_id = @bank_id, @bank_transaction_type_id = @bank_transaction_type_id, @amount = @payment_amount, @bank_transaction_id = @bank_transaction_id output, @error = @error output, @approval_override_flag = 1, @bank_contract_id = @bank_contract_id

		if @bank_transaction_id is not null
		begin
			insert into cust_payment (cust_id, cust_payment_type_id, cust_payment_status_id, payment_amount, bank_transaction_id, inserted_by)
			select @cust_id, @cust_payment_type_id, cust_payment_status_id, @payment_amount, @bank_transaction_id, @inserted_by
			from cust_payment_status
			where code = 'NEW'

			set @cust_payment_id = SCOPE_IDENTITY()
		end
		else
		begin
			set @error = isnull(@error, 'Failed to create bank transaction; ')
		end
	end

	if @cust_payment_type in ('CUSTOMER_BANK_TRANSACTION','CREDIT_CARD')
	begin
		insert into cust_payment (cust_id, cust_payment_type_id, cust_payment_status_id, payment_date, payment_amount, settlement_date, tran_num, inserted_by)
		select @cust_id, @cust_payment_type_id, cust_payment_status_id, @payment_date, @payment_amount, case @cust_payment_type when 'CREDIT_CARD' then @settlement_date end, @tran_num, @inserted_by
		from cust_payment_status
		where code = 'PAID'

		set @cust_payment_id = SCOPE_IDENTITY()
	end

	if @cust_payment_type in ('WRITE_OFF','TV_TAX_WRITE_OFF')
	begin
		insert into cust_payment (cust_id, cust_payment_type_id, cust_payment_status_id, payment_date, payment_amount, inserted_by)
		select @cust_id, @cust_payment_type_id, cust_payment_status_id, isnull(@payment_date,getdate()), @payment_amount, @inserted_by
		from cust_payment_status
		where code = 'PAID'

		set @cust_payment_id = SCOPE_IDENTITY()
	end
end
go

