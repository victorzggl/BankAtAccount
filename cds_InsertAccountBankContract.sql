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
declare @end_previous_bank_contract_flag bit = 0, @ProcName varchar(100) = 'cds_InsertAccountBankContract'

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

	if exists(select 1 from bank_contract bc
					where bc.bank_contract_id = @bank_contract_id
					and exists(select 1 from bank_contract b join account_bank_contract abc on abc.bank_contract_id = b.bank_contract_id
									where b.cust_id = bc.cust_id and b.bank_id = bc.bank_id and abc.account_id = @account_id and b.bank_contract_id <> bc.bank_contract_id
									and b.end_date is null

							)
			)
		set @end_previous_bank_contract_flag = 1

end


if @error = ''
begin
	insert into account_bank_contract (account_id, bank_contract_id, start_date, end_date, active_flag)
	select @account_id, bank_contract_id, start_date, end_date, case when end_date is null then 1 else 0 end active_flag
	from bank_contract bc
	where bc.bank_contract_id = @bank_contract_id
	and (contract_id is not null and bc.bank_contract_status_id = @bank_contract_status_ACTIVE or bc.bank_contract_status_id = @bank_contract_status_NEW)
	and not exists(select 1 from account_bank_contract abc where abc.bank_contract_id = @bank_contract_id and abc.account_id = @account_id)

	if @end_previous_bank_contract_flag = 1
	begin
		create table #end_bank_contract(bank_contract_id int not null, end_date date not null )

		begin try
			update abc set end_date = dateadd(d,-1,bc2.start_date), active_flag = 0
			output inserted.bank_contract_id, inserted.end_date into #end_bank_contract (bank_contract_id, end_date)
			from bank_contract bc
			join bank_contract bc2 on bc2.cust_id = bc.cust_id and bc2.bank_id = bc.bank_id and bc2.bank_contract_id <> bc.bank_contract_id
			join account_bank_contract abc on abc.bank_contract_id = bc.bank_contract_id and abc.account_id = @account_id
			where bc2.bank_contract_id = @bank_contract_id
			and bc.end_date is null
			and bc2.end_date is null
			and abc.end_date is null

		end try
		begin catch
			set @error = concat('; end_previous_bank_contract failed {account_id:',@account_id,',bank_contract_id:', @bank_contract_id,'}')
			delete #end_bank_contract
			exec dba_InsertProcError @ProcName = @ProcName, @InternalError = @error

		end catch

		if @error = ''
		begin

			update bc set end_date = ebc.end_date, bc.bank_contract_status_id = bcs.bank_contract_status_id
			from bank_contract bc
			join #end_bank_contract ebc on ebc.bank_contract_id = bc.bank_contract_id
			cross join bank_contract_status bcs
			where not exists(select 1 from account_bank_contract abc where abc.bank_contract_id = bc.bank_contract_id and abc.end_date is null )
			and bcs.code = 'INACTIVE'
		end
	end
end


