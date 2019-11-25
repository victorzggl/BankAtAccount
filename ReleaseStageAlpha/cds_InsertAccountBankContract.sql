use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure dbo.cds_InsertAccountBankContract @account_id int, @bank_contract_id int, @error varchar(500) output as

set @error = ''

declare @bank_contract_status_NEW int = (select bank_contract_status_id from bank_contract_status where code = 'NEW'),
 		@bank_contract_status_ACTIVE int = (select bank_contract_status_id from bank_contract_status where code = 'ACTIVE')

declare @ProcName varchar(100) = 'cds_InsertAccountBankContract', @account_bank_contract_id int, @previous_active_bank_contract_id int = 0, @previous_active_account_id int,  @cds_EndAccountBankContract_error varchar(500) = ''

if not exists (select * from account a where account_id = @account_id)
	set @error += '; must be valid account_id'
if not exists (select * from bank_contract a where bank_contract_id = @bank_contract_id)
	set @error += '; must be valid bank_contract_id'

if @error = ''
begin
	if exists(select * from bank_contract bc where bank_contract_id = @bank_contract_id and (contract_id is not null and bc.bank_contract_status_id <> @bank_contract_status_ACTIVE))
		set @error += '; bank_contract_status must be in ACTIVE'

	else if exists(select * from bank_contract bc where bank_contract_id = @bank_contract_id and (bank_contract_status_id <> @bank_contract_status_NEW))
		set @error += '; bank_contract_status must be in NEW'

-- 	else if exists(select * from account_bank_contract where bank_contract_id = @bank_contract_id and account_id = @account_id)
-- 		set @error += '; account_bank_contract already exists'

	else if exists(select * from bank_contract bc join cust c on c.cust_id = bc.cust_id join account a on a.cust_id = c.cust_id where bc.bank_contract_id = @bank_contract_id and a.account_id = @account_id)
		set @error += '; cust_id in bank_contract must match cust_id of the account'
end


if @error = ''
begin
	insert into account_bank_contract (account_id, bank_contract_id, start_date, end_date, active_flag)
	select @account_id, bank_contract_id, start_date, end_date, case when end_date is null then 1 else 0 end active_flag
	from bank_contract bc
	where bc.bank_contract_id = @bank_contract_id
	and (bc.contract_id is not null and bc.bank_contract_status_id = @bank_contract_status_ACTIVE or bc.bank_contract_status_id = @bank_contract_status_NEW)
	and not exists(select 1 from account_bank_contract abc where abc.bank_contract_id = @bank_contract_id and abc.account_id = @account_id)

	set @account_bank_contract_id = scope_identity()


end

if @error = '' and @account_bank_contract_id is not null
begin
	while @previous_active_bank_contract_id is not null and @error = ''
	begin
		select @previous_active_bank_contract_id = null, @previous_active_account_id = null , @cds_EndAccountBankContract_error = ''


		select @previous_active_bank_contract_id = gabc.bank_contract_id, @previous_active_account_id = pabc.account_id
		from account_bank_contract abc
		join bank_contract bc on bc.bank_contract_id = abc.bank_contract_id
		cross apply dbo.cds_fn_GetActiveBankForAccount (@account_id, null, null) gabc
		join account_bank_contract pabc on pabc.bank_contract_id = gabc.bank_contract_id
		where gabc.account_id = pabc.account_id
		and pabc.end_date is not null
		and pabc.account_bank_contract_id <> @account_bank_contract_id
		and abc.account_bank_contract_id = @account_bank_contract_id
		and bc.bank_id = gabc.bank_id

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
begin
	set @error = concat(@error,'; {account_id:', @account_id, ',bank_contract_id:', @bank_contract_id, '}')
	exec dba_InsertProcError @ProcName = @ProcName, @InternalError = @error
end


