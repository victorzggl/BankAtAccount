use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[cds_InsertAccountActionMaster] @TranCode varchar(50) , @InsertFlag bit = 0--This flag doesn't work for REINSTATE_RSP since it uses account_action_id
as

--cds_InsertAccountActionMaster @TranCode = 'CHANGE_REQ', @InsertFlag = 1
--cds_InsertAccountActionMaster @TranCode = 'ENROLL_REQ', @InsertFlag = 1
--cds_InsertAccountActionMaster @TranCode = 'HIST_REQ', @InsertFlag = 1
--cds_InsertAccountActionMaster @TranCode = 'DROP_REQ', @InsertFlag = 1
--cds_InsertAccountActionMaster @TranCode = 'REINSTATE_RSP', @InsertFlag = 1
--cds_InsertAccountActionMaster @TranCode = 'ENROLL_RESCIND_REQ', @InsertFlag = 1


declare @ProcName varchar(100), @Process varchar(1000), @Error varchar(1000), @TranDate date, @new_account_status_id int, @change_code_id int

set @ProcName = 'cds_InsertAccountActionMaster'

set @TranDate = getdate()

create table #t2 (id int identity(1,1), account_id int, account_action_id int, change_code_id int, interval_flag bit default (0), only_one_814_request_per_day_flag bit default(0), cust_id int null)
create clustered index id on #t2(id)


if @TranCode in ('CHANGE_REQ')
	begin
		create table #account_change_req
		(account_change_req_id int identity(1,1) NOT NULL primary key,
		account_id int not null,
		change_code_id int not null)

		insert into #account_change_req (account_id, change_code_id)
		exec cds_InsertAccountActionMaster_ChangeRequest

		insert into #t2 (account_id, change_code_id)
		select a.account_id,  cr.change_code_id
		from account a
		join #account_change_req cr on cr.account_id = a.account_id
		join change_code cc on cc.change_code_id = cr.change_code_id
		join esco_utility_commodity euc on euc.esco_id = a.esco_id and euc.utility_id = a.utility_id and euc.commodity_id = a.commodity_id
		join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
		where (fs.create_change_req_flag = 1 or cc.code = 'INTERVAL_STATUS')
		and ((datediff(DD,a.verif_date, @TranDate) - (datediff(WK,a.verif_date,@TranDate) * 2) - case when datepart(DW,a.verif_date) = 1 then 1 else 0 end + case when datepart(DW,@TranDate) = 1 then 1 else 0 end >= euc.enrollment_resi_wait_days and a.facility_id = 1) --Residential
			or (datediff(DD,a.verif_date, @TranDate) - (datediff(WK,a.verif_date,@TranDate) * 2) - case when datepart(DW,a.verif_date) = 1 then 1 else 0 end + case when datepart(DW,@TranDate) = 1 then 1 else 0 end >= euc.enrollment_comm_wait_days and a.facility_id = 2)) --Commercial

		--ESCO_ACCOUNT_NUM needs to send regardless of create_change_req_flag value
		insert into #t2 (account_id, change_code_id)
		select a.account_id, cr.change_code_id
		from account a
		join #account_change_req cr on cr.account_id = a.account_id
		join utility u on u.utility_id = a.utility_id
		join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
		join change_code cc on cc.change_code_id = cr.change_code_id
		where fs.create_change_req_flag = 0
		and cc.code = 'ESCO_ACCOUNT_NUM'

		drop table #account_change_req
	end

--History requests need to be done first since the Enrollments change the account status to ENROLL_SENT and then wouldn't be picked up by this query
if @TranCode in ('HIST_REQ')
	begin
		insert into #t2 (account_id)
		select a.account_id
		from account a
		join account_status s on s.account_status_id = a.account_status_id
		join utility u on u.utility_id = a.utility_id
		join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
		where s.code in('SENT_ESCO','RESENT_ESCO','REINSTATEMENT_ESCO','HOLD')--*******may need to handle REINSTATEMENT_PENDING and could add code here to force histories for certain accounts maybe a flag in account table if needed*********
		and fs.create_hist_req_flag = 1

		insert into #t2 (account_id)
		select account_id
		from account a
		join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
		where (a.force_history_req_flag = 1 or a.force_history_interval_req_flag = 1)
		and fs.create_hist_req_flag = 1
		except
		select account_id
		from #t2

		update t set interval_flag = 1
		from #t2 t
		join account a on t.account_id = a.account_id
		where a.force_history_interval_req_flag = 1

		--remove if any hist_req in last 3 days
		delete t
		from #t2 t
		join account_action aa on t.account_id = aa.account_id
		join tran_code tc on aa.tran_code_id = tc.tran_code_id
		join file_type ft on aa.file_type_id = ft.file_type_id
		where tc.code = 'HIST_REQ'
		and ft.to_utility_flag = 1
		and aa.tran_date > dateadd(day,-3,cast(getdate() as date))

		--remove if successful hist_req in last 30 days
		delete t
		from #t2 t
		join account_action req on t.account_id = req.account_id
		join account_action rsp on req.response_account_action_id = rsp.account_action_id
		join tran_code tc on req.tran_code_id = tc.tran_code_id
		join file_type ft on req.file_type_id = ft.file_type_id
		join response_code rc on rsp.response_code_id = rc.response_code_id
		where tc.code = 'HIST_REQ'
		and ft.to_utility_flag = 1
		and rc.code = 'ACCEPTED'
		and ((t.interval_flag = 1 and req.change_value = 'interval')
			or t.interval_flag = 0)
		and req.tran_date > dateadd(day,-30,cast(getdate() as date))

		--If PRECHECK data is populated then no need to send another gas history request
		delete t
		from #t2 t
		where exists (select * from account a join commodity c on a.commodity_id = c.commodity_id where c.code = 'G' /*and a.axpo_esco_gas_id is not null*/ and a.sii_precheck_account_type_id is not null and a.utility_sub_id is not null and a.area_meter_num is not null and t.account_id = a.account_id)

		update a set force_history_req_flag = 0, force_history_interval_req_flag = 0
		from account a
		join #t2 t on a.account_id = t.account_id
        where @InsertFlag = 1
		and (a.force_history_req_flag = 1
			or a.force_history_interval_req_flag = 1)
	end


if @TranCode in ('ENROLL_REQ')
begin
	select s.code as status_code, u.code as utility_code, a.account_id, a.verif_date, euc.enrollment_resi_wait_days, euc.enrollment_comm_wait_days, a.facility_id,
		0 as pool_code_flag, 0 as tax_rate_flag
	into #t -- TSK TSK TSK
	from account a
	join account_status s on s.account_status_id = a.account_status_id
	join commodity c on c.commodity_id = a.commodity_id
	join utility u on u.utility_id = a.utility_id
	join esco_utility_commodity euc on euc.esco_id = a.esco_id and euc.utility_id = a.utility_id and euc.commodity_id = a.commodity_id
	join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id

	cross apply dbo.cds_fn_GetActiveBankForAccount (a.account_id, null, 1, null) b
	where b.account_id = a.account_id /*do not pass @cust_id to cds_fn_GetActiveBankForAccount in case a different cust added this cust's account to their bank_contract */
	and s.code in('SENT_ESCO','RESENT_ESCO','REINSTATEMENT_ESCO')-- *****could include holds for reporting but removed below if inserting into account_action ****
	and fs.create_enroll_req_flag = 1
	and (euc.no_enroll_start_day is null or day(getdate()) not between euc.no_enroll_start_day and euc.no_enroll_end_day)

	and exists (select * from account_contract ac where a.account_id = ac.account_id and ac.end_date is null)
	and (c.code = 'E'
		or (c.code = 'G' and a.sii_precheck_account_type_id is not null /*and a.axpo_esco_gas_id is not null*/ and a.utility_sub_id is not null and a.gas_use_type_id is not null and a.area_meter_num is not null and nullif(a.meter_num,'') is not null))
	order by s.code

	insert into #t (status_code, utility_code, account_id, verif_date, enrollment_resi_wait_days, enrollment_comm_wait_days, facility_id, pool_code_flag, tax_rate_flag)
	select s.code as status_code, u.code as utility_code, a.account_id, a.verif_date, euc.enrollment_resi_wait_days, euc.enrollment_comm_wait_days, a.facility_id,
		0 as pool_code_flag, 0 as tax_rate_flag
	from account a
	join account_status s on s.account_status_id = a.account_status_id
	join commodity c on c.commodity_id = a.commodity_id
	join utility u on u.utility_id = a.utility_id
	join esco_utility_commodity euc on euc.esco_id = a.esco_id and euc.utility_id = a.utility_id and euc.commodity_id = a.commodity_id
	join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
	left join
		(select aa.account_id, max(aa.tran_date) [tran_date]
		from account_action aa
		join file_type ft on aa.file_type_id = ft.file_type_id
		where aa.tran_code_id = 9 --ENROLL_REQ
		and ft.to_utility_flag = 1
		group by aa.account_id) aa on a.account_id = aa.account_id
	left join utility_bill_cycle bc on a.utility_id = bc.utility_id and a.commodity_id = bc.commodity_id and a.bill_cycle = bc.bill_cycle
	where s.code = 'ENROLL_REJECTED_NOT_FIRST_IN'
	and ((bc.utility_bill_cycle_id is null and aa.tran_date <= cast(dateadd(day,-3,getdate()) as date))
		or (bc.bill_cycle_year = year(getdate()) and bc.bill_cycle_month = month(getdate()) and aa.tran_date <= bc.meter_read_date))
	and fs.create_enroll_req_flag = 1
	and (euc.no_enroll_start_day is null or day(getdate()) not between euc.no_enroll_start_day and euc.no_enroll_end_day)
	and exists (select 1 from dbo.cds_fn_GetActiveBankForAccount(a.account_id, null, null, null ) gabfa )
	and exists (select 1 from account_contract ac where a.account_id = ac.account_id and ac.end_date is null)
	and (c.code = 'E'
		or (c.code = 'G' and a.sii_precheck_account_type_id is not null /*and a.axpo_esco_gas_id is not null*/ and a.utility_sub_id is not null and a.gas_use_type_id is not null and a.area_meter_num is not null and nullif(a.meter_num,'') is not null))

	insert into #t2 (account_id)
	select account_id
	from #t
	where pool_code_flag = 0
	and tax_rate_flag = 0
	and status_code in('SENT_ESCO','RESENT_ESCO','REINSTATEMENT_ESCO','ENROLL_REJECTED_NOT_FIRST_IN')
	and ((datediff(DD,verif_date, @TranDate) - (datediff(WK,verif_date,@TranDate) * 2) - case when datepart(DW,verif_date) = 1 then 1 else 0 end + case when datepart(DW,@TranDate) = 1 then 1 else 0 end >= enrollment_resi_wait_days and facility_id = 1) --Residential
		or (datediff(DD,verif_date, @TranDate) - (datediff(WK,verif_date,@TranDate) * 2) - case when datepart(DW,verif_date) = 1 then 1 else 0 end + case when datepart(DW,@TranDate) = 1 then 1 else 0 end >= enrollment_comm_wait_days and facility_id = 2)) --Commercial
end

if @TranCode = 'DROP_REQ'
begin
	set @Process = 'update account status during DROP_REQ to CANCELLED_NO_INVOICE'
	begin try
		update a set account_status_id = 2--CANCELLED
		--select a.*
		from account a
		join account_status s on s.account_status_id = a.account_status_id
		join commodity c on c.commodity_id = a.commodity_id
		join utility u on u.utility_id = a.utility_id
		join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
		where s.code in('CANCEL_PENDING')
		and fs.create_drop_req_flag = 1
		and exists(select 1 from account_status_log l--If the account status was last SENT_ESCO or RESENT_ESCO don't send drop request but instead set to cancelled.
								join (select max(account_status_log_id) account_status_log_id
										from account_status_log l
										where l.account_id = a.account_id
										and account_status_id <> 17--CANCEL_PENDING
										) ml on ml.account_status_log_id = l.account_status_log_id
								where  account_status_id in(10, 5))--SENT_ESCO, RESENT_ESCO
	end try
	begin catch
		execute dba_InsertProcError @ProcName, @Process
	end catch

	insert into #t2 (account_id)
	select a.account_id
	from account a
	join account_status s on s.account_status_id = a.account_status_id
	join commodity c on c.commodity_id = a.commodity_id
	join utility u on u.utility_id = a.utility_id
	join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
	where s.code in('CANCEL_PENDING')
	and fs.create_drop_req_flag = 1

	--do not send drops for gas that went from ENROLL_SENT to CANCEL_PENDING if current day of month between 1st and 10th - send rescind instead
	delete t
	from #t2 t
	join account a on t.account_id = a.account_id
	join account_status s on a.account_status_id = s.account_status_id
	join commodity c on a.commodity_id = c.commodity_id
	join
		(select account_id, account_status_id, rank() over (partition by account_id order by account_status_log_id desc) [rank]
		from account_status_log) l on a.account_id = l.account_id
	join account_status ls on l.account_status_id = ls.account_status_id
	where s.code = 'CANCEL_PENDING'
	--and c.code = 'G'
	and datepart(day,getdate()) between 1 and case c.code when 'G' then 10 when 'E' then 8 end
	and l.[rank] = 2
	and (a.[start_date] > cast(getdate() as date) or a.[start_date] is null)
	and ls.code in ('ENROLL_SENT','ACTIVE')
end


if @TranCode = 'REINSTATE_RSP'
begin
	insert into #t2 (account_id, account_action_id)
	select aa.account_id, aa.account_action_id
	from account_action aa
	join account_action_status s on s.account_action_status_id = aa.account_action_status_id
	join account a on a.account_id = aa.account_id
	join tran_code tc on tc.tran_code_id = aa.tran_code_id
	join utility_file_setup fs on fs.esco_id = a.esco_id and fs.utility_id = a.utility_id and fs.commodity_id = a.commodity_id
	join file_type ft on ft.file_type_id = aa.file_type_id
	where s.code = 'PROCESSED'
	and tc.code = 'REINSTATE_REQ'
	and fs.create_reinstate_rsp_flag = 1
	and ft.code <> 'FROM_UI'
end


if @TranCode = 'ENROLL_RESCIND_REQ'
begin
	insert into #t2 (account_id, account_action_id)
	select a.account_id, aa.account_action_id
	from account a
	join account_status s on a.account_status_id = s.account_status_id
	join
		(select aa.account_id, max(aa.account_action_id) [account_action_id]
		from account_action aa
		join file_type ft on aa.file_type_id = ft.file_type_id
		join tran_code tc on aa.tran_code_id = tc.tran_code_id
		join change_code cc on aa.change_code_id = cc.change_code_id
		where aa.reason is not null
		and ft.code = 'FROM_AXPO'
		and tc.code = 'CHANGE_REQ'
		and cc.code = 'START_DATE'
		group by aa.account_id) aa on a.account_id = aa.account_id
	where s.code = 'ENROLL_RESCIND_PENDING'

	insert into #t2 (account_id)
	select a.account_id
	from account a
	join account_status s on a.account_status_id = s.account_status_id
	join commodity c on a.commodity_id = c.commodity_id
	join
		(select account_id, account_status_id, rank() over (partition by account_id order by account_status_log_id desc) [rank]
		from account_status_log) l on a.account_id = l.account_id
	join account_status ls on l.account_status_id = ls.account_status_id
	where s.code = 'CANCEL_PENDING'
	--and c.code = 'G'
	and datepart(day,getdate()) between 1 and case c.code when 'G' then 10 when 'E' then 8 end
	and l.[rank] = 2
	and (a.[start_date] > cast(getdate() as date) or a.[start_date] is null)
	and ls.code in ('ENROLL_SENT','ACTIVE')

	insert into #t2 (account_id)
	select a.account_id
	from account a
	join account_status s on a.account_status_id = s.account_status_id
	where s.code = 'ENROLL_RESCIND_PENDING'
	and a.account_id not in (select account_id from #t2)
end

if @TranCode in ('CERTIFIED_COLLECTIONS_EMAIL_REQ')
begin
	insert into #t2(account_id, cust_id)
	exec cds_GetCertifiedCollectionsEmailAccount
end

if @TranCode in ('SUSPENSION_REQ')
begin
	insert into #t2(account_id, cust_id)
	exec cds_GetSuspendReqAccount
end

if @TranCode in ('UNSUSPEND_REQ')
begin
	insert into #t2(account_id, cust_id)
	exec cds_GetUnSuspendReqAccount
end

if @InsertFlag = 1
	begin

		begin try
			set @Process = 'set account_action_status_id to NEEDS_REVIEW'

			update req
			set req.account_action_status_id = 6, --NEEDS_REVIEW
				req.note = isnull(req.note,'') + ' No response to request.'
			from account_action req
			join account a on req.account_id = a.account_id
			join tran_code tc on req.tran_code_id = tc.tran_code_id
			join file_type ft on req.file_type_id = ft.file_type_id
			join account_action_response_delay aard on aard.tran_code_id = tc.tran_code_id and aard.commodity_id = a.commodity_id and aard.utility_id = a.utility_id
			where tc.tran_purpose = 'REQUEST'
			and ft.code like 'TO%'
			and req.response_account_action_id is null
			and dbo.cds_fn_DayDiff(req.tran_date,@TranDate,aard.exclude_weekend_flag) > aard.expected_days
			and req.account_action_status_id in (4,1) --PROCESSED, LOADED
		end try
		begin catch
			execute dba_InsertProcError @ProcName, @Process
		end catch

		begin try
			set @Process = 'set account_action_status_id to SYSTEM_REVIEWED'
			exec cds_ProcessAccountActionNeedingReview @TranCode = @TranCode, @Error = @Error output
		end try
		begin catch
			set @Error = concat(@Process, ' ', @Error)
			execute dba_InsertProcError @ProcName, @Error
		end catch

		update t set only_one_814_request_per_day_flag = 1
		from #t2 t
		join account a on t.account_id = a.account_id
		join utility_commodity uc on a.utility_id = uc.utility_id and a.commodity_id = uc.commodity_id
		where uc.only_one_814_request_per_day_flag = 1

		declare @i int, @Total int, @account_id int, @account_action_id int, @interval_flag bit, @only_one_814_request_per_day_flag bit, @cust_id int
		set @i = 1
		select @Total = max(id) from #t2

		while @i <= @Total
			begin
				if exists (select 1 from #t2 where id = @i)
				begin
					select @account_id = null, @account_action_id = null, @change_code_id = null, @interval_flag = null, @only_one_814_request_per_day_flag = null, @cust_id = null

					select @account_id = account_id, @account_action_id = account_action_id, @change_code_id = change_code_id, @interval_flag = interval_flag, @only_one_814_request_per_day_flag = only_one_814_request_per_day_flag, @cust_id = cust_id
					from #t2 where id = @i

					if not exists --check if a LOADED account_action record already exists
						(select 1
						from account_action aa
						join file_type ft on aa.file_type_id = ft.file_type_id
						join account_action_status s on aa.account_action_status_id = s.account_action_status_id
						where aa.account_id = @account_id
						and ft.to_utility_flag = 1
						and cast(aa.load_date as date) = cast(getdate() as date)
						and @only_one_814_request_per_day_flag = 1)
					begin
						set @Process = 'cds_InsertAccountAction'
						begin try
							begin tran
								--select @i, @account_id
								execute cds_InsertAccountAction @account_id= @account_id, @account_action_id=@account_action_id, @TranCode=@TranCode, @TranDate=@TranDate, @change_code_id=@change_code_id, @interval_flag=@interval_flag, @cust_id=@cust_id

								if exists
									(select *
									from account a
									join utility u on a.utility_id = u.utility_id
									where a.account_id = @account_id
									and u.meter_interval_flag = 1
									and @TranCode = 'ENROLL_REQ')
									begin
										execute cds_InsertAccountAction @account_id=@account_id, @account_action_id=@account_action_id, @TranCode='INTERVAL_REQ', @TranDate=@TranDate
									end

								if @TranCode in ('ENROLL_REQ')
									begin
										update account set account_status_id = 19, updated_by = 'SYSTEM' where account_id = @account_id --ENROLL_SENT
									end

								if @TranCode in ('DROP_REQ')
									begin
										update account set account_status_id = 20, updated_by = 'SYSTEM' where account_id = @account_id --CANCEL_SENT
									end

								if @TranCode in ('ENROLL_RESCIND_REQ')
									begin
										update account set account_status_id = 34, updated_by = 'SYSTEM' where account_id = @account_id --ENROLL_RESCIND_SENT
									end
							commit tran
						end try
						begin catch
							rollback tran
							execute dba_InsertProcError @ProcName, @Process
						end catch
					end
				end
				set @i += 1
			end
	end
else
	begin
		select t.status_code, t.utility_code, a.account_date, c.cust_id, c.cust_num, a.account_id, a.account_num, a.account_name,
		--t.rate_class_flag,
		--a.rate_class,
		--t.rate_flag,
		t.pool_code_flag,
		a.pool_code,
		t.tax_rate_flag,
		a.tax_rate
		from #t t
		join account a on a.account_id = t.account_id
		join cust c on c.cust_id = a.cust_id
		--where --rate_class_flag = 1 
		----or rate_flag = 1
		--pool_code_flag = 1
		--or tax_rate_flag = 1
	end
go

