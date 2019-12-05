use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure dbo.[cds_EndBankContract]
	@cust_id int = null,
	@bank_id int = null,
	@bank_contract_id int = null,
	@error varchar(500) = null output
as

set @error = ''

declare @EndAccountBankContract_error varchar(500) = ''

create table #bank_contract (bank_contract_id int primary key not null)

if @cust_id is null and @bank_id is null and @bank_contract_id is null
	set @error = 'check input (@cust_id is null and @bank_account is null and @document_key is null and @bank_id is null and @account_id is null)'


else if @error = ''
begin

	update b set end_date = getdate(), b.bank_contract_status_id = s.bank_contract_status_id, updated_date = getdate()
	output inserted.bank_contract_id into #bank_contract (bank_contract_id)
	from bank_contract b
	cross apply bank_contract_status s
	where s.code = 'INACTIVE'
	and b.bank_id = isnull(@bank_id, b.bank_id)
	and b.bank_contract_id = isnull(@bank_contract_id, b.bank_contract_id)
	and b.cust_id = isnull(@cust_id, b.cust_id)
	and b.end_date is null

	if not exists(select 1 from #bank_contract )
		set @error = '; no update done invalid input'

	else if @error = ''
	begin
		while exists(select 1 from #bank_contract b join account_bank_contract abc on abc.bank_contract_id = b.bank_contract_id where abc.end_date is null )
		begin
			select @bank_contract_id =  min(bank_contract_id),  @EndAccountBankContract_error = ''
			from #bank_contract c

			begin try
				exec cds_EndAccountBankContract @bank_contract_id = @bank_contract_id, @error = @EndAccountBankContract_error output
			end try
			begin catch
				set @EndAccountBankContract_error = concat(@EndAccountBankContract_error,'; cds_EndBankContract raised an exception')
			end catch

			select @error = concat(@error, @EndAccountBankContract_error)

			delete bc from #bank_contract bc where bc.bank_contract_id = @bank_contract_id

		end

	end



end

if @error <> ''
	set @error = concat(@error, '; {bank_id:', @bank_id, ',bank_contract_id:', @bank_contract_id, '}')


go

