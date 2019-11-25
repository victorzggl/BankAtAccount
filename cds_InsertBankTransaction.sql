
CREATE procedure [dbo].[cds_InsertBankTransaction] @bank_id int, @bank_transaction_type_id int, @amount decimal(18,2), @bank_transaction_id int = null output, @error varchar(500) = null output, @approval_override_flag bit = 0
as

/*
declare @bank_transaction_id int, @error varchar(500),
		@bank_id int = 5,
		@amount decimal(18,2) = 258.89,
		@bank_transaction_type_id int = (select bank_transaction_type_id from bank_transaction_type where code = 'WITHDRAW')

exec cds.dbo.cds_InsertBankTransaction @bank_id = @bank_id, @bank_transaction_type_id = @bank_transaction_type_id, @amount = @amount, @bank_transaction_id = @bank_transaction_id output, @error = @error output

select @bank_transaction_id [bank_transaction_id], @error [error]
*/

declare @bank_transaction_status_id int,
		@bank_status_PENDING int = (select bank_status_id from bank_status where code = 'PENDING'),
		@bank_status varchar(50) = (select bs.code from bank b join bank_status bs on b.bank_status_id = bs.bank_status_id where b.bank_id = @bank_id),
		@bank_transaction_type varchar(50) = (select code from bank_transaction_type where bank_transaction_type_id = @bank_transaction_type_id)

select @bank_transaction_status_id = bank_transaction_status_id 
from bank_transaction_status 
where code = case when @bank_transaction_type in ('VALIDATION_PAYMENT','VALIDATION_WITHDRAW') or @approval_override_flag = 1 then 'NEW' else 'NEEDS_APPROVAL' end

select @bank_transaction_id = null, @error = ''

if @bank_status is null
	set @error += '; must be valid bank_id'

if @bank_transaction_type is null
	set @error += '; must be valid bank_transaction_type_id'

if @amount <= 0
	set @error += '; amount must be positive'

if @bank_status not in ('NEW','ACTIVE','NEEDS_REVIEW') and @bank_transaction_type not in ('VALIDATION_PAYMENT','VALIDATION_WITHDRAW')
	set @error += '; bank record must be in NEW, ACTIVE, or NEEDS_REVIEW'

if @bank_status = 'NEW' and @bank_transaction_type not in ('VALIDATION_PAYMENT','VALIDATION_WITHDRAW')
	set @error += '; NEW bank record must be validated first'

if @error = ''
begin
	if @bank_transaction_type in ('PAYMENT','VALIDATION_PAYMENT')
		set @amount = -@amount

	insert into bank_transaction (bank_id, bank_transaction_type_id, bank_transaction_status_id, tran_amount, tran_date)
	select @bank_id, @bank_transaction_type_id, @bank_transaction_status_id, @amount, getdate()

	set @bank_transaction_id = SCOPE_IDENTITY()

	if @bank_status = 'NEW'
		update bank set bank_status_id = @bank_status_PENDING, bank_status_date = getdate() where bank_id = @bank_id
end

if @error = ''
	set @error = null
go

