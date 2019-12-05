use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure dbo.[cds_InsertBankContract]
	@cust_id int,
	@bank_type_id int,
	@bank_account varchar(100),
	@bank_account_name varchar(100),
	@signatory_contact_id int,
	@signatory_email varchar(255),
	@signatory_name varchar(101) = null,
	@signatory_personal_tax_num varchar(100) = null,
	@document_key varchar(100) = null,
	@signed_date datetime = null,
	@bank_id int = null output,
	@bank_contract_id int = null output,
	@error varchar(500) = null output
as

set @error = ''

if not exists (select * from bank_type where bank_type_id = @bank_type_id)
	set @error += '; must be valid bank_type_id'

if not exists (select * from cust where cust_id = @cust_id)
	set @error += '; must be valid cust_id'

if nullif(@signatory_email,'') is null
	set @error += '; @signatory_email cannot be blank'


if not exists(select 1 from contact c where contact_id = @signatory_contact_id)
	set @error += '; must be valid contact_id'
else
begin
	select @signatory_name = isnull(@signatory_name, nullif(first_name,'') + ' ' + nullif(last_name,'')), @signatory_personal_tax_num = isnull(@signatory_personal_tax_num, personal_tax_num)
	from contact c
	where contact_id = @signatory_contact_id

	if nullif(@signatory_name,'') is null
		set @error += '; @signatory_name cannot be blank'

	if nullif(@signatory_personal_tax_num,'') is null
		set @error += '; @signatory_personal_tax_num cannot be blank'

end

if nullif(@bank_account ,'') is null
	set @error += '; bank_account cannot be blank'

if nullif(@bank_account_name,'') is null
	set @error += '; bank_account_name cannot be blank'

if @bank_account in ('IT05S0103024801000001003495','IT14X0103024801000001003305','IT19C0103024801000000990063','IT38E0103024801000000990156','IT03X0103024801000000993512')
	set @error += '; bank_account not valid for customer use'

select @bank_id = null, @bank_contract_id = null

if @error = ''
begin
	declare @bank_contract_status_NEW int = (select bank_contract_status_id from bank_contract_status where code = 'NEW'),
	 		@bank_contract_status_PENDING int = (select bank_contract_status_id from bank_contract_status where code = 'PENDING')
	declare @contract_id int, @description varchar(100) = '', @bank_contract_status int, @ProcName varchar(100) = 'cds_InsertBankContract'

	select @bank_contract_id = bc.bank_contract_id, @contract_id = c.contract_id, @signed_date = coalesce(bc.signed_date, c.signed_date, @signed_date), @bank_account = coalesce(bc.bank_account, c.bank_account, @bank_account), @bank_id = bc.bank_id, @signatory_email = coalesce(bc.signatory_email, c.contract_email, @signatory_email)
	from bank_contract bc
	join cds_fn_GetActiveBankContract (null, null, null ) gabc on gabc.bank_contract_id = bc.bank_contract_id
	full join contract c on c.document_key = bc.document_key
	where (bc.document_key = @document_key or c.document_key = @document_key)

	if @contract_id is not null
		set @bank_contract_status = @bank_contract_status_PENDING -- PDF ALREADY GENERATED bank_contract and contract are 1 document key
	else
		set @bank_contract_status = @bank_contract_status_NEW

	set @bank_id = (select bank_id from bank where bank_account = @bank_account and cust_id = @cust_id)

	if @bank_contract_id is null
	begin
		begin transaction
		begin try
			insert into bank_contract (bank_contract_status_id, cust_id, start_date, document_key, signatory_email, signatory_name, signatory_contact_id, signatory_personal_tax_num, bank_account_name, bank_account, contract_id, bank_type_id, bank_id)
			select @bank_contract_status, @cust_id, @signed_date start_date, @document_key, @signatory_email, @signatory_name, @signatory_contact_id, @signatory_personal_tax_num, @bank_account_name, @bank_account, @contract_id, @bank_type_id, @bank_id
		end try
		begin catch
			set @error = concat(error_message(), '; Failed to insert bank_contract {document_key: "', @document_key, '"} ')
		end catch

		set @bank_contract_id = scope_identity()

		if @contract_id is not null
		begin
			begin try
				exec cds_SignBankContract @signed_date = @signed_date, @document_key = @document_key, @error = @error output
			end try
			begin catch
				set @error = concat(@error, '; Failed to sign bank_contract')
			end catch
		end

		if @bank_id is not null and @error = ''
		begin
			begin try
				-- THIS IS A NEW BANK_CONTRACT SAME CUST & BANK REFRESH BANK FROM BANK_CONTRACT
				exec cds_UpdateBank @bank_contract_id = @bank_contract_id, @error = @error output
			end try
			begin catch
				set @error = isnull(@error, '; cds_UpdateBank threw an exception')
			end catch

			set @error = isnull(@error, '; cds_UpdateBank returned an null @error')
		end

		else if @error = ''
		begin
			begin try
				exec cds_InsertBank
				@description = @description,
				@bank_id = @bank_id output,
				@error = @error output,
				@bank_contract_id = @bank_contract_id
			end try
			begin catch
				set @error = isnull(@error,'; failed to insert bank')
			end catch

			set @error = isnull(@error, case when @bank_id is null then 'cds_InsertBank did not return a @bank_id' else '' end)

			update bc set bank_id = @bank_id, bank_reg_key = dbo.cds_fn_GetBankRegKey (@bank_contract_id)
			from bank_contract bc
			where bank_contract_id = @bank_contract_id
			and @error = ''

		if @error = ''
			commit transaction
		else
		begin

			rollback transaction

			set @error = concat(@error, '{document_key: "', @document_key, '", bank_contract_id:', @bank_contract_id ,'}')

			exec dba_InsertProcError @ProcName = @ProcName, @InternalError = @error
		end

		end
	end
end








/*select *
into #bank
from bank b
select *
into #contract
from contract b
delete c3 from #contract c3 where document_key = 'Ncxugo3BQcReZmKMhSJ8pE'
delete c3 from #bank  c3 where document_key = '22e9UBgdfAi9xcKGf6cyYR'*/

go

