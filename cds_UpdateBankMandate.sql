use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_UpdateBankMandate] @bank_id int, @bank_account_key varchar(50) = null, @bank_authorization_key varchar(100) = null, @error_message varchar(max) = null
as

if exists (select * from bank where bank_id = @bank_id and bank_authorization_key is null)
begin
	if @bank_authorization_key is not null and @error_message is null
	begin
		update b set bank_account_key = isnull(bank_account_key,@bank_account_key), bank_authorization_key = @bank_authorization_key, error = null
		from bank b
		where bank_id = @bank_id
	end
	else
	begin
		update b set bank_account_key = isnull(bank_account_key,@bank_account_key), error = @error_message
		from bank b
		where bank_id = @bank_id
	end

	declare @bank_status_NEW int = (select bank_status_id from bank_status where code = 'NEW')

	if exists (select * from bank where bank_id = @bank_id and bank_account_key is not null and bank_authorization_key is not null and bank_status_id = @bank_status_NEW)
	begin
		declare @csr_id int,
				@cust_id int,
				@bank_transaction_type_id int,
				@amount decimal(18,2),
				@amount_VALIDATION_WITHDRAW decimal(18,2) = .01

		select @csr_id = csr_id, @cust_id = cust_id 
		from bank 
		where bank_id = @bank_id

		if @csr_id is not null
		begin
			set @bank_transaction_type_id = (select bank_transaction_type_id from bank_transaction_type where code = 'VALIDATION_PAYMENT')
			set @amount = rand()
		end

		if @cust_id is not null
		begin
			set @bank_transaction_type_id = (select bank_transaction_type_id from bank_transaction_type where code = 'VALIDATION_WITHDRAW')
			set @amount = @amount_VALIDATION_WITHDRAW
		end

		exec cds_InsertBankTransaction @bank_id = @bank_id, @bank_transaction_type_id = @bank_transaction_type_id, @amount = @amount

		if exists (select *
					from bank b
					join bank b2 on (b.csr_id = b2.csr_id or b.cust_id = b2.cust_id) and b.bank_id <> b2.bank_id
					join bank_transaction bt on b2.bank_id = bt.bank_id
					join bank_transaction_type btt on bt.bank_transaction_type_id = btt.bank_transaction_type_id
					join bank_transaction_status bts on bt.bank_transaction_status_id = bts.bank_transaction_status_id
					where b.bank_id = @bank_id
					and bt.resubmitted_bank_transaction_id is null
					and bt.hide_ui_flag = 0
					and btt.code in ('PAYMENT','WITHDRAW')
					and bts.code in ('FAIL','CHARGED_BACK'))
		begin
			exec cds_ActivateBank @bank_id = @bank_id
		end
	end
end
go

