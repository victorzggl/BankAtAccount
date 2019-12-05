use CDS
go
set ansi_nulls on
go
set quoted_identifier on
go

create procedure dbo.cds_SignBankContract @signed_date date, @document_key varchar(100), @error varchar(500) = null output as

set @error = ''
declare @contract_status_ACTIVE int = (select contract_status_id from contract_status where code = 'ACTIVE'),
		@contract_status_PENDING int = (select contract_status_id from contract_status where code = 'PENDING'),
		@contract_status_NEEDS_REVIEW int = (select contract_status_id from contract_status where code = 'NEEDS_REVIEW')

declare @bank_contract_status int, @bank_contract_id int, @previous_active_bank_contract_id int = 0, @previous_active_account_id int,  @cds_EndAccountBankContract_error varchar(500) = ''

if nullif(@document_key,'') is null
	set @error += '; document_key cannot be blank'
else
	set @bank_contract_id = (select document_key from bank_contract bc where document_key = @document_key)


if @bank_contract_id is null
	set @error += '; document_key must exist in bank_contract'
else if exists(select 1 from bank_contract where bank_contract_id = @bank_contract_id and signed_date is not null )
	set @error += '; bank_contract already signed'
else
begin
	set @bank_contract_status = (select bank_contract_status_id from bank_contract b where @bank_contract_id = b.bank_contract_id)

	if @bank_contract_status not in (@contract_status_PENDING, @contract_status_NEEDS_REVIEW)
		set @error += concat('; bank_contract_status must be PENDING XOR NEEDS_REVIEW {@bank_contract_status:', @bank_contract_status,'}')
end

if @signed_date is null
	set @error += '; signed_date cannot be blank'


if @error = ''
begin
	update bc set signed_date = @signed_date
	from bank_contract bc
	where bank_contract_id = @bank_contract_id
	and signed_date is null

	set @bank_contract_status = @contract_status_ACTIVE

end

if @error = ''
begin
	while @previous_active_bank_contract_id is not null and @error = ''
	begin
		select @previous_active_bank_contract_id = null, @previous_active_account_id = null , @cds_EndAccountBankContract_error = ''

		select @previous_active_bank_contract_id = gabc.bank_contract_id, @previous_active_account_id = pabc.account_id
		from bank_contract bc
		join account_bank_contract abc on abc.bank_contract_id = bc.bank_contract_id
		cross apply dbo.cds_fn_GetActiveBankContract(null, bc.cust_id, null) gabc
		join account_bank_contract pabc on pabc.bank_contract_id = gabc.bank_contract_id
		where bc.bank_contract_id = @bank_contract_id
		and abc.account_id = pabc.account_id
		and pabc.end_date is not null
		and gabc.bank_id = bc.bank_id


		begin try
			if @previous_active_bank_contract_id is not null
				exec cds_EndAccountBankContract @account_id = @previous_active_account_id, @bank_contract_id = @previous_active_bank_contract_id, @error = @cds_EndAccountBankContract_error output
		end try
		begin catch
			set @cds_EndAccountBankContract_error = concat(@cds_EndAccountBankContract_error , '; cds_EndAccountBankContract raised an error')
		end catch

		if @cds_EndAccountBankContract_error <> ''
			set @error = isnull(@cds_EndAccountBankContract_error , '; cds_EndAccountBankContract returned null for @error')

	end
end

if @error <> ''
	select @bank_contract_status = isnull(@bank_contract_status, @contract_status_NEEDS_REVIEW), error = concat(@error, '{@document_key:','"',@document_key,'"',', @bank_contract_id:',@bank_contract_id,'}')

-- set signatory_ord_contact_id in case updates are made to the contact
update bc
set signatory_contact_id    = c.contact_id,
	bank_contract_status_id = case when bc.bank_contract_id = @bank_contract_id then @bank_contract_status else @contract_status_ACTIVE end,
	error                   = case when bc.bank_contract_id = @bank_contract_id then nullif(@error,'') end
from contact c
cross join bank_contract bc
where bc.signatory_contact_id is null
and bc.cust_id = c.cust_id and bc.signatory_contact_id = c.contact_id
and bc.bank_contract_status_id in (@contract_status_PENDING, @contract_status_NEEDS_REVIEW)
and bc.signed_date is not null

