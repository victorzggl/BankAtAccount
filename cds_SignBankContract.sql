use CDS
go
set ansi_nulls on
go
set quoted_identifier on
go


/*TODO @GregG: to sign a bank_contract call  cds_SignBankContract*/
create procedure dbo.cds_SignBankContract @signed_date date, @document_key varchar(100), @error varchar(500) = null output as

set @error = ''
declare @contract_status_ACTIVE int = (select contract_status_id from contract_status where code = 'ACTIVE'),
		@contract_status_PENDING int = (select contract_status_id from contract_status where code = 'PENDING'),
		@contract_status_NEEDS_REVIEW int = (select contract_status_id from contract_status where code = 'NEEDS_REVIEW')
declare @bank_contract_status int, @bank_contract_id int

if nullif(@document_key,'')
	set @error += '; document_key cannot be blank'
else
	set @bank_contract_id = (select document_key from bank_contract bc where document_key = @document_key)


if @bank_contract_id is null
	set @error += '; document_key must exist in bank_contract'
else if exists(select 1 from bank_contract where bank_contract_id = @bank_contract_id and signed_date is not null )
	set @error += concat('; bank_contract already signed {@document_key:','"',@document_key,'"',', @bank_contract_id:',@bank_contract_id,'}')
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

-- set signatory_ord_contact_id in case updates are made to the contact
update bc
set signatory_contact_id    = c.contact_id,
	bank_contract_status_id = case when bc.bank_contract_id = @bank_contract_id then @bank_contract_status else @contract_status_ACTIVE end,
	error                   = case when bc.bank_contract_id = @bank_contract_id then @error end
from contact c
cross join bank_contract bc
where bc.signatory_contact_id is null
and bc.cust_id = c.cust_id and bc.signatory_contact_id = c.contact_id
and bc.bank_contract_status_id in (@contract_status_PENDING, @contract_status_NEEDS_REVIEW)
and bc.signed_date is not null

