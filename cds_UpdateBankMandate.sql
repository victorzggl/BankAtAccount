use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[cds_UpdateBankMandate] @bank_contract_id int, @bank_account_key varchar(50) = null, @bank_authorization_key varchar(100) = null, @error_message varchar(max) = null
as

declare @bank_id int = (select bank_contract_id from bank_contract bc where bank_contract_id = @bank_contract_id)

set @error_message = isnull(@error_message,'')

if not exists (select 1 from bank_contract where bank_contract_id = @bank_contract_id)
	set @error_message += '; must be valid bank_contract_id'
if '; must be valid bank_contract_id' not in @error_message
begin
	if not exists (select 1 from cds_fn_GetActiveBankContract (null, null,null) gabc )
		set @error_message += concat('; bank_contract_id {', @bank_contract_id, '} is not ACTIVE or end_date is set')
	if @bank_id is null
		set @error_message += '; bank_contract.bank_id is null'
	if not exists (select 1 from bank_contract where bank_contract_id = @bank_contract_id and bank_authorization_key is null) and @error_message = ''
		set @error_message += concat('; could not update bank_authorization_key to {''', @bank_authorization_key, '''} bank_contract.bank_authorization_key already exists')
end



if exists (select * from bank_contract where bank_contract_id = @bank_contract_id and bank_authorization_key is null)
begin
	if @bank_authorization_key is not null and @error_message = ''
	begin
		update b set bank_account_key = isnull(bank_account_key, @bank_account_key), bank_authorization_key = @bank_authorization_key, error = null
		from bank b
		where bank_id = @bank_id

		update bc set bank_authorization_key = @bank_authorization_key from bank_contract bc where bank_contract_id = @bank_contract_id and bank_authorization_key is null

	end
	else
	begin
		update bc set error = @error_message
		from bank_contract bc
		where bc.bank_contract_id = @bank_contract_id
	end

	declare @bank_status_NEW int = (select bank_status_id from bank_status where code = 'NEW')
	if @error_message = ''
	begin
		if exists (select * from bank where bank_id = @bank_id and bank_account_key is not null and bank_authorization_key is not null and bank_status_id = @bank_status_NEW)
		begin
			declare	@bank_transaction_type_id int,
					@amount decimal(18,2),
					@amount_VALIDATION_WITHDRAW decimal(18,2) = .01

			set @bank_transaction_type_id = (select bank_transaction_type_id from bank_transaction_type where code = 'VALIDATION_WITHDRAW')
			set @amount = @amount_VALIDATION_WITHDRAW

			exec cds_InsertBankTransaction @bank_id = @bank_id, @bank_transaction_type_id = @bank_transaction_type_id, @amount = @amount

			exec cds_ActivateBank @bank_id = @bank_id

		end

	end
end
go

