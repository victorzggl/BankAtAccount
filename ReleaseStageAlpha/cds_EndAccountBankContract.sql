use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure dbo.[cds_EndAccountBankContract]
	@account_id int = null,
	@bank_contract_id int = null,
	@error varchar(500) = null output
as

declare @bank_contract as table (bank_contract_id int not null)

declare @EndBankContract_error varchar(500), @ProcName varchar(100) = 'cds_EndAccountBankContract'
set @error = ''

if not exists(select 1 from account_bank_contract abc where account_id = @account_id or bank_contract_id = @bank_contract_id)
	set @error += '; account_bank_contract must exist'


else if @error = ''
begin

	update abc set end_date = (case when end_date > cast( getdate() as date) then dateadd(day, 1, end_date) else getdate() end )
	output inserted.bank_contract_id into @bank_contract (bank_contract_id)
	from account_bank_contract abc
	where abc.end_date is null
	and abc.account_id = isnull(@account_id, account_id)
	and abc.bank_contract_id = isnull(@bank_contract_id, bank_contract_id)

	delete b  -- where other active accounts for a bank contract exist.
	from @bank_contract b
	where exists(
		select 1
		from account_bank_contract abc
		join bank_contract bc on bc.bank_contract_id = abc.bank_contract_id
		where abc.bank_contract_id = b.bank_contract_id and bc.end_date is null and abc.end_date is null
		)

end


if @error = ''
begin
	while exists(select 1 from @bank_contract b)
	begin
		select @bank_contract_id =  min(bank_contract_id),  @EndBankContract_error = ''
		from @bank_contract c

		begin try
			exec cds_EndBankContract @bank_contract_id = @bank_contract_id, @error = @EndBankContract_error output
		end try
		begin catch
			set @EndBankContract_error = concat(@EndBankContract_error,'; cds_EndBankContract raised an exception')
		end catch

		select @error = concat(@error, @EndBankContract_error)

		delete bc from @bank_contract bc where bank_contract_id = @bank_contract_id

	end
end

if @error <> ''
begin
	set @error = concat(@error, '; {account_id:', @account_id,' , bank_contract_id:', @bank_contract_id, '}')
	exec dba_InsertProcError @ProcName = @ProcName, @InternalError = @error
end

go

