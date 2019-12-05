use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure dbo.[cds_UpdateBank]
	@bank_contract_id int,
	@error varchar(500) = null output
as
set @error = ''

declare @bank_status_NEW int = (select bank_status_id from bank_status where code = 'NEW'),
		@bank_status_NEEDS_REVIEW int = (select bank_status_id from bank_status where code = 'NEEDS_REVIEW')

declare @bank_id int, @run_date datetime = getdate()


if @bank_contract_id is null
	set @error += '; @bank_contract_id cannot be null'

select @bank_id = bank_id
from bank_contract bc
where bc.bank_contract_id = @bank_contract_id


if @bank_id is null
	select @error += concat('; @bank_contract_id: ', @bank_contract_id, 'does not have a bank_id assigned' )

if @error = ''
	if exists(select 1 from bank b join bank_contract c on c.bank_id = b.bank_id where c.bank_contract_id = @bank_contract_id and b.bank_id = @bank_id and c.document_key = b.document_key )
		select @error += concat('; document_key is the same in bank and bank_contract for @bank_contract_id: ', @bank_contract_id, 'updating bank without an new document key is not allowed' )


if @error = ''
begin
	update b set
	bank_account_name = bc.bank_account_name,
	bank_authorization_key = null,
	bank_account_key = b.bank_account_key, -- explicitly keep this the same mollie cst_key
	bank_account = b.bank_account, -- explicitly keep this the same IBAN
	bank_status_date = @run_date,
	validated_date = null,
	validated_flag = 0,
	updated_date = @run_date,
	bank_status_id = @bank_status_NEW,
	bank_reg_key = dbo.cds_fn_GetBankRegKey(@bank_contract_id),
	description = '',
	signed_date = bc.signed_date,
	document_key = bc.document_key
	from bank b
	join bank_contract bc on bc.bank_id = b.bank_id
	where b.bank_id = @bank_id

end
else
begin
	update b set error = @error, bank_status_id = @bank_status_NEEDS_REVIEW from bank b where bank_id = @bank_id and error <> @error
end
go

