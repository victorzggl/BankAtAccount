use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[cds_ProcessAccountAction] @file_batch_id int = null, @TranCode varchar(50) = null, @FileTypeCode varchar(50) = null, @Error varchar(max) = '' output
as
set @Error = ''
--exec [cds_ProcessAccountAction] @file_batch_id = 3347

set nocount on
create table #email_list (email_sent varchar(255) primary key not null, email_responded_to varchar(255) null )

--drop table #t
CREATE TABLE #t(
	id int identity(1,1) NOT NULL primary key,
	tran_code varchar(50),
	response_code varchar(50),
	change_code varchar(50),
	account_id int NULL,
	utility_id int NULL,
	account_action_id int null,
	[account_action_type_id] [int] NULL,
	[account_action_status_id] [int] NULL,
	[file_type_id] [int] NULL,
	[file_row_id] [int] NULL,
	[tran_code_id] [int] NULL,
	[response_code_id] [int] NULL,
	[change_code_id] [int] NULL,
	[rate] [decimal](18, 10) NULL,
	[process_date] [datetime] NULL,
	[effective_date] [date] NULL,
	[margin_id] [int] NULL,
	[reason] [varchar](1000) NULL,
	request_tracking_num varchar(100) NULL,
	response_tracking_num varchar(100) NULL,
	tran_date date,
	cancel_reason_id int,
	sub_tracking_num varchar(50),
	change_value varchar(4000) NULL,
	use_account_action_request_tracking_num_for_reponse_flag bit,
	account_num varchar(50),
	peak_demand decimal(18,4) NULL,
	arrears_date date NULL,
	bill_cycle varchar(50) NULL,
	meter_read_cycle varchar(50) NULL,
	bi_monthly_invoice_flag bit,
	capacity decimal(18,6) NULL,
	transmission decimal(18,6) NULL,
	load_profile_code varchar(50) NULL,
	rate_class varchar(50) NULL,
	rate_sub_class varchar(50) NULL,
	loss_factor decimal(18,6) NULL,
	billing_type_id int NULL,
	account_name varchar(100) NULL,
	[address] varchar(100) NULL,
	city varchar(100) NULL,
	state_id int NULL,
	zip varchar(100) NULL,
	bill_account_name varchar(100) NULL,
	bill_address varchar(100) NULL,
	bill_city varchar(100) NULL,
	bill_state_id int NULL,
	bill_zip varchar(100) NULL,
	axpo_esco_gas_id int NULL,
	sii_precheck_account_type_id int NULL,
	utility_sub_id int NULL,
	area_meter_num varchar(100) NULL,
	meter_type_id int NULL,
	voltage decimal(18,6) NULL,
	protection_service_id int NULL
	)


INSERT INTO #t
	(
	tran_code
	,response_code
	,change_code
	,account_id
	,utility_id
	,account_action_id
	,account_action_type_id
	,account_action_status_id
	,file_type_id
	,file_row_id
	,tran_code_id
	,response_code_id
	,change_code_id
	,rate
	,process_date
	,effective_date
	,margin_id
	,reason
	,request_tracking_num
	,response_tracking_num
	,tran_date
	,cancel_reason_id
	,sub_tracking_num
	,change_value
	,use_account_action_request_tracking_num_for_reponse_flag
	,account_num
	,peak_demand
	,arrears_date
	,bill_cycle
	,meter_read_cycle
	,bi_monthly_invoice_flag
	,capacity
	,transmission
	,load_profile_code
	,rate_class
	,rate_sub_class
	,loss_factor
	,billing_type_id
	,account_name
	,[address]
	,city
	,state_id
	,zip
	,bill_account_name
	,bill_address
	,bill_city
	,bill_state_id
	,bill_zip
	,axpo_esco_gas_id
	,sii_precheck_account_type_id
	,utility_sub_id
	,area_meter_num
	,meter_type_id
	,voltage
	,protection_service_id
	)
select tc.code, rc.code, cc.code,
	aa.account_id
	,aa.utility_id
	,aa.account_action_id
	,aa.account_action_type_id
	,aa.account_action_status_id
	,aa.file_type_id
	,aa.file_row_id
	,aa.tran_code_id
	,aa.response_code_id
	,aa.change_code_id
	,aa.rate
	,aa.process_date
	,aa.effective_date
	,aa.margin_id
	,aa.reason
	,aa.request_tracking_num
	,aa.response_tracking_num
	,aa.tran_date
	,rr.cancel_reason_id
	,aa.sub_tracking_num
	,aa.change_value
	,m.use_account_action_request_tracking_num_for_reponse_flag
	,a.account_num
	,aa.peak_demand
	,aa.arrears_date
	,aa.bill_cycle
	,aa.meter_read_cycle
	,aa.bi_monthly_invoice_flag
	,aa.capacity
	,aa.transmission
	,aa.load_profile_code
	,aa.rate_class
	,aa.rate_sub_class
	,aa.loss_factor
	,aa.billing_type_id
	,aa.account_name
	,aa.[address]
	,aa.city
	,aa.state_id
	,aa.zip
	,aa.bill_account_name
	,aa.bill_address
	,aa.bill_city
	,aa.bill_state_id
	,aa.bill_zip
	,aa.axpo_esco_gas_id
	,aa.sii_precheck_account_type_id
	,aa.utility_sub_id
	,aa.area_meter_num
	,aa.meter_type_id
	,aa.voltage
	,aa.protection_service_id
from account_action aa
join account a on aa.account_id = a.account_id
join utility u on u.utility_id = a.utility_id
join market m on m.market_id = u.market_id
join file_type ft on ft.file_type_id = aa.file_type_id
join account_action_status s on s.account_action_status_id = aa.account_action_status_id
left outer join tran_code tc on tc.tran_code_id = aa.tran_code_id
left outer join response_code rc on rc.response_code_id = aa.response_code_id
left outer join change_code cc on cc.change_code_id = aa.change_code_id
left outer join account_action_response_reason rr on rr.reason = replace(replace(aa.reason,a.account_num,''),'_',' ')
where (ft.from_utility_flag = 1 or (ft.code = @FileTypeCode and ft.code like 'FROM%'))
and s.code = 'LOADED'
and (aa.file_batch_id = @file_batch_id or @file_batch_id is null)
and (tc.code = @TranCode or @TranCode is null)
order by aa.account_action_id



declare @i int, @Total int, @account_id int, @account_action_id int, @tran_code varchar(50), @response_code varchar(50), @change_code varchar(50),
		@response_tracking_num varchar(50), @effective_date date, @current_account_status varchar(50), @tran_date date, @CurrentAccountCancelStatusFlag bit,
		@cancel_reason_id int, @sub_tracking_num varchar(50), @change_value varchar(4000), @start int, @length int, @change_date date,
		@use_account_action_request_tracking_num_for_reponse_flag bit, @request_tracking_num varchar(50), @reason varchar(1000), @account_num varchar(50),
		@peak_demand decimal(18,4), @arrears_date date, @bill_cycle varchar(50), @meter_read_cycle varchar(50), @bi_monthly_invoice_flag bit,
		@capacity decimal(18,6), @transmission decimal(18,6), @load_profile_code varchar(50), @rate_class varchar(50), @rate_sub_class varchar(50),
		@loss_factor decimal(18,6), @billing_type_id int, @file_type_id int,
		@account_name varchar(100), @address varchar(100), @city varchar(100), @state_id int, @zip varchar(100),
		@bill_account_name varchar(100), @bill_address varchar(100), @bill_city varchar(100), @bill_state_id int, @bill_zip varchar(100),
		@axpo_esco_gas_id int, @sii_precheck_account_type_id int, @utility_sub_id int, @area_meter_num varchar(100),
		@meter_type_id int, @voltage decimal(18,6), @protection_service_id int, @destination_cust_id int, @source_cust_id int,
		@cust_merge_flag bit = 0, @RemoteError varchar(max) = '', @to_email_csv_list varchar(1000),@max_days_certified_collections_email_receipt_date int = 4

declare
		@CERTIFIED_COLLECTIONS_EMAIL_RSP_tran_code_id int = (select tran_code_id from tran_code where code = 'CERTIFIED_COLLECTIONS_EMAIL_RSP'),
		@CERTIFIED_COLLECTIONS_EMAIL_REQ_tran_code_id int = (select tran_code_id from tran_code where code = 'CERTIFIED_COLLECTIONS_EMAIL_REQ'),
		@RESPONDED_TO_account_action_status_id int = (select account_action_status_id from account_action_status where code = 'RESPONDED_TO'),
		@NEEDS_REVIEW_account_action_status_id int = (select account_action_status_id from account_action_status where code = 'NEEDS_REVIEW'),
		@SUSPENDED_account_suspension_status_id int = (select account_suspension_status_id from account_suspension_status ass where code = 'SUSPENDED'),
		@OPEN_account_suspension_status_id int = (select account_suspension_status_id from account_suspension_status ass where code = 'OPEN')

set @i = 1
select @Total = max(id)
from #t

while @i <= @Total
	begin
		select @account_id = account_id, @account_action_id = account_action_id, @tran_code = tran_code, @response_code = response_code,
		@change_code = change_code, @response_tracking_num = response_tracking_num, @effective_date = effective_date, @tran_date = tran_date,
		@cancel_reason_id = cancel_reason_id, @sub_tracking_num = sub_tracking_num, @change_value = change_value, @request_tracking_num = request_tracking_num,
		@use_account_action_request_tracking_num_for_reponse_flag = use_account_action_request_tracking_num_for_reponse_flag, @reason = reason, @account_num = account_num,
		@peak_demand = peak_demand, @arrears_date = arrears_date, @bill_cycle = bill_cycle, @meter_read_cycle = meter_read_cycle, @bi_monthly_invoice_flag = bi_monthly_invoice_flag,
		@capacity = capacity, @transmission = transmission, @load_profile_code = load_profile_code, @rate_class = rate_class, @rate_sub_class = rate_sub_class,
		@loss_factor = loss_factor, @billing_type_id = billing_type_id, @file_type_id = file_type_id,
		@account_name = account_name, @address = [address], @city = city, @state_id = state_id, @zip = zip,
		@bill_account_name = bill_account_name, @bill_address = bill_address, @bill_city = bill_city, @bill_state_id = bill_state_id, @bill_zip = bill_zip,
		@axpo_esco_gas_id = axpo_esco_gas_id, @sii_precheck_account_type_id = sii_precheck_account_type_id, @utility_sub_id = utility_sub_id, @area_meter_num = area_meter_num,
		@meter_type_id = meter_type_id, @voltage = voltage, @protection_service_id = protection_service_id, @to_email_csv_list = null

		from #t where id = @i
		truncate table #email_list
		--select @i, @account_id
		select @destination_cust_id = null , @Error = ''

		select @current_account_status = s.code, @CurrentAccountCancelStatusFlag = s.cancel_status_flag
		from account a
		join account_status s on s.account_status_id = a.account_status_id
		where a.account_id = @account_id

		if @tran_code = 'ENROLL_RSP'
			begin
				--This will update the account_num
				if @change_value is not null
					begin
						begin try
							set @change_value = 'update a set ' + @change_value + char(10) + '--select *' + char(10) + 'from account a where account_id = ' + convert(varchar,@account_id)
							exec (@change_value)
						end try
						begin catch
							EXECUTE dba_InsertProcError 'cds_ProcessAccountAction', 'update account'
						end catch
					end

				if (@response_code = 'ACCEPTED' and @effective_date is not null)
					begin
						exec cds_UpdateAccountServicePeriod @account_id = @account_id, @effective_date = @effective_date, @start_flag = 1, @change_flag = 0
					end

				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = @RESPONDED_TO_account_action_status_id
						from account_action aa where aa.request_tracking_num = @request_tracking_num and aa.account_id = @account_id and aa.account_action_id <> @account_action_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = @RESPONDED_TO_account_action_status_id
						from account_action aa where aa.sub_tracking_num = @sub_tracking_num and aa.account_id = @account_id and aa.account_action_id <> @account_action_id
					end

				if @response_code = 'ACCEPTED' and @current_account_status in('ENROLL_SENT', 'ACTIVE')
					begin

						update a set account_status_id = 1, --ACTIVE
									[start_date] = @effective_date,
									end_date = dateadd(YY,2,@effective_date),--default to a 2 year contract date, this could be moved to utility or ESCO
									accept_date = case when account_status_id = 1 and accept_date is not null then accept_date else getdate() end,
									utility_cancelled_flag = 0,
									peak_demand = @peak_demand,
									arrears_date = @arrears_date,
									bill_cycle = @bill_cycle,
									meter_read_cycle = @meter_read_cycle,
									bi_monthly_invoice_flag = @bi_monthly_invoice_flag,
									capacity = isnull(@capacity,capacity),
									transmission = isnull(@transmission,transmission),
									load_profile_code = isnull(@load_profile_code,load_profile_code),
									rate_class = isnull(@rate_class,rate_class),
									rate_sub_class = isnull(@rate_sub_class,rate_sub_class),
									loss_factor = isnull(@loss_factor,loss_factor),
									billing_type_id = isnull(@billing_type_id,billing_type_id),
									dual_billing_date = null,
									account_name = isnull(@account_name,account_name),
									[address] = isnull(@address,[address]),
									city = isnull(@city,city),
									state_id = isnull(@state_id,state_id),
									zip = isnull(@zip,zip),
									bill_account_name = isnull(@bill_account_name,bill_account_name),
									bill_address = isnull(@bill_address,bill_address),
									bill_city = isnull(@bill_city,bill_city),
									bill_state_id = isnull(@bill_state_id,bill_state_id),
									bill_zip = isnull(@bill_zip,bill_zip),
									orig_enroll_date = isnull(orig_enroll_date,@effective_date),
									last_enroll_date = @effective_date,
									meter_type_id = isnull(@meter_type_id,meter_type_id),
									voltage = isnull(@voltage,voltage),
									protection_service_id = isnull(@protection_service_id,protection_service_id)
						from account a
						where a.account_id = @account_id

						update a set force_history_interval_req_flag = 1, force_meter_interval_req_flag = 1
						from account a
						join utility u on a.utility_id = u.utility_id
						where a.account_id = @account_id
						and @peak_demand > u.min_peak_demand_for_interval

						update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
						from account_action aa where aa.account_action_id = @account_action_id

						execute cds_InsertAccountNote @account_id=@account_id ,@note='Account has been accepted by utility.'
					end
				else
					begin

						if @response_code = 'REJECTED' and @current_account_status in('ENROLL_SENT','ENROLL_REJECTED_NOT_FIRST_IN')
							begin

								update a set account_status_id = isnull(rr.new_account_status_id,21), --ENROLL_REJECTED
											cancel_date = case when rr.new_account_status_id = 2 /*CANCELLED*/ then getdate() else a.cancel_date end,
											cancel_reason_id = case when rr.new_account_status_id = 2 /*CANCELLED*/ then isnull(rr.cancel_reason_id,a.cancel_reason_id) else a.cancel_reason_id end
								from account a
								left join account_action_response_reason rr on rr.reason = replace(replace(@reason,@account_num,''),'_',' ')
								where a.account_id = @account_id

								update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
								from account_action aa where aa.account_action_id = @account_action_id

							end
						else
							begin

								if @response_code = 'ACCEPTED' and @CurrentAccountCancelStatusFlag = 1
									begin
										update a
										set accept_date = getdate(), [start_date] = @effective_date, end_date = dateadd(yy, 2, @effective_date)
										from account a where a.account_id = @account_id

										update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
													,note = 'Account was in one of the CANCELLED statuses so was not set to active'
										from account_action aa where aa.account_action_id = @account_action_id
									end
								else
									begin
										update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
													,note = 'Account in wrong status to update to active per utilitys response.'
										from account_action aa where aa.account_action_id = @account_action_id
									end
							end
					end

				if @response_code = 'ACCEPTED' and @effective_date is null
					begin
						update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
									,note = 'Effective date is null.'
						from account_action aa
						join account a on aa.account_id = a.account_id
						where aa.account_action_id = @account_action_id
						and aa.account_action_status_id <> @NEEDS_REVIEW_account_action_status_id
					end
			end

		if @tran_code = 'DROP_REQ'
			begin
				if (@effective_date is not null)
					begin
						exec cds_UpdateAccountServicePeriod @account_id = @account_id, @effective_date = @effective_date, @start_flag = 0, @change_flag = 0
					end

				if @CurrentAccountCancelStatusFlag = 1 or  @current_account_status in('SENT_ESCO', 'RESENT_ESCO', 'ENROLL_SENT', 'ENROLL_REJECTED', 'ENROLL_FAIL', 'ENROLL_REVIEW', 'ACTIVE', 'REINSTATEMENT_PENDING', 'CANCEL_REJECTED', 'HOLD')
					begin

						update a set
							account_status_id = 2, --CANCELLED

							end_date = case when @FileTypeCode = 'FROM_UI' and [start_date] is null then null else @effective_date end,

							cancel_date =
							case
								when @CurrentAccountCancelStatusFlag <> 1 then getdate()
								else a.cancel_date
							end,
							cancel_reason_id = @cancel_reason_id,
							utility_cancelled_flag = case when @FileTypeCode = 'FROM_UI' then 0 else 1 end

						from account a
						join account_status s on s.account_status_id = a.account_status_id
						where a.account_id = @account_id

						update a
						set end_date = [start_date]
						from account a
						where a.account_id = @account_id
						and end_date < [start_date]

						if @effective_date is not null
						begin
							update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
							from account_action aa where aa.account_action_id = @account_action_id
						end
						else
						begin
							update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
									,note = 'Effective date is null.'
							from account_action aa where aa.account_action_id = @account_action_id
						end

						execute cds_InsertAccountNote @account_id=@account_id ,@note='Account has been cancelled by request from utility or UI.'

					end

				else
					begin
						update aa set account_action_status_id = @NEEDS_REVIEW_account_action_status_id
								,note = 'Account in wrong status to cancel per request of utility or UI.'
						from account_action aa where aa.account_action_id = @account_action_id
					end
			end

		if @tran_code = 'DROP_RSP'
			begin
				if (@response_code = 'ACCEPTED' and @effective_date is not null)
					begin
						exec cds_UpdateAccountServicePeriod @account_id = @account_id, @effective_date = @effective_date, @start_flag = 0, @change_flag = 0
					end
				--select @account_id, @account_action_id, @response_code, @CurrentAccountCancelStatusFlag--Debugging code


				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = @RESPONDED_TO_account_action_status_id
						from account_action aa where aa.request_tracking_num = @request_tracking_num and aa.account_id = @account_id and aa.account_action_id <> @account_action_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = @RESPONDED_TO_account_action_status_id
						from account_action aa where aa.sub_tracking_num = @sub_tracking_num and aa.account_id = @account_id and aa.account_action_id <> @account_action_id
					end

				update a set
					account_status_id =
					case
						when @response_code = 'ACCEPTED' and @CurrentAccountCancelStatusFlag = 1 then 2 --CANCELLED
						when @response_code = 'REJECTED' and @current_account_status not in('CANCELLED', 'CANCELLED_NO_INVOICE') then 23 --CANCEL_REJECTED
						else a.account_status_id
					end,

					end_date =
					case
						when @response_code = 'ACCEPTED' and @CurrentAccountCancelStatusFlag = 1 and @effective_date is not null then @effective_date
						else a.end_date
					end

				from account a
				join account_status s on s.account_status_id = a.account_status_id
				where a.account_id = @account_id

				if @response_code = 'REJECTED'
				begin
					update a set a.account_status_id = rr.drop_reject_account_status_id
					from account a
					cross join account_action_response_reason rr
					where a.account_id = @account_id
					and a.account_status_id <> rr.drop_reject_account_status_id
					and rr.reason = replace(@reason,@account_num,'')
					and rr.drop_reject_account_status_id is not null

					select @CurrentAccountCancelStatusFlag = s.cancel_status_flag
					from account a
					join account_status s on a.account_status_id = s.account_status_id
					where a.account_id = @account_id
				end

				update a
				set end_date = [start_date]
				from account a
				where a.account_id = @account_id
				and end_date < [start_date]

				if @response_code = 'ACCEPTED' and @CurrentAccountCancelStatusFlag = 1
					begin
						update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
						from account_action aa where aa.account_action_id = @account_action_id

						execute cds_InsertAccountNote @account_id=@account_id ,@note='Account cancellation has been accepted by utility.'
					end
				else
					begin
						if  @response_code = 'REJECTED' and @CurrentAccountCancelStatusFlag = 1
							begin
								--update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
								--from account_action aa where aa.account_action_id = @account_action_id
								update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
										,note = 'Account already in cancel-type status.'
								from account_action aa where aa.account_action_id = @account_action_id

								execute cds_InsertAccountNote @account_id=@account_id ,@note='Account cancellation has been rejected by utility, usually because they already cancelled it.'
							end
						else
							begin
								update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
										,note = 'Account in wrong status to update to cancelled per utilitys response.'
								from account_action aa where aa.account_action_id = @account_action_id
							end
					end

				declare @recent_drop_flag bit = 0

				select @recent_drop_flag = 1
				from account_action aa
				join tran_code tc on aa.tran_code_id = tc.tran_code_id
				join file_type ft on aa.file_type_id = ft.file_type_id
				where aa.account_id = @account_id
				and aa.effective_date is not null
				and aa.tran_date >= cast(dateadd(day,-3,getdate()) as date)
				and ft.from_utility_flag = 1
				and tc.code = 'DROP_REQ'

				if @response_code = 'ACCEPTED' and @effective_date is null and @recent_drop_flag = 0
					begin
						update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
									,note = 'Effective date is null.'
						from account_action aa
						join account a on aa.account_id = a.account_id
						where aa.account_action_id = @account_action_id
						and aa.account_action_status_id <> @NEEDS_REVIEW_account_action_status_id
					end
			end

		if @tran_code = 'HIST_RSP'
			begin
				if exists (select * from file_type where file_type_id = @file_type_id and code = 'FROM_AXPO') and exists (select * from account a join commodity c on a.commodity_id = c.commodity_id where a.account_id = @account_id and c.code = 'G')
					begin
						update a set axpo_esco_gas_id = isnull(@axpo_esco_gas_id,axpo_esco_gas_id),
									sii_precheck_account_type_id = isnull(@sii_precheck_account_type_id,sii_precheck_account_type_id),
									utility_sub_id = isnull(@utility_sub_id,utility_sub_id),
									area_meter_num = isnull(@area_meter_num,area_meter_num)
						from account a
						where a.account_id = @account_id

						if @response_code = 'REJECTED' and @current_account_status in('SENT_ESCO','RESENT_ESCO')
							begin
								update a set account_status_id = s.account_status_id
								from account a
								cross join account_status s
								where a.account_id = @account_id
								and s.code = 'ENROLL_REJECTED'
							end
					end

				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = @RESPONDED_TO_account_action_status_id
						from account_action aa where aa.request_tracking_num = @request_tracking_num and aa.account_id = @account_id and aa.account_action_id <> @account_action_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = @RESPONDED_TO_account_action_status_id
						from account_action aa where aa.sub_tracking_num = @sub_tracking_num and aa.account_id = @account_id and aa.account_action_id <> @account_action_id
					end

				update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
				from account_action aa where aa.account_action_id = @account_action_id
			end

		if @tran_code = 'REINSTATE_REQ'
			begin
				if (@effective_date is not null)
					begin
						exec cds_UpdateAccountServicePeriod @account_id = @account_id, @effective_date = @effective_date, @start_flag = 1, @change_flag = 0
					end

				if @CurrentAccountCancelStatusFlag = 1 or  @current_account_status in('REINSTATEMENT_ESCO', 'REINSTATEMENT_PENDING', 'SENT_ESCO', 'RESENT_ESCO', 'ENROLL_SENT', 'ENROLL_REJECTED', 'ENROLL_FAIL', 'ENROLL_REVIEW', 'ACTIVE', 'ENROLL_REJECTED_NOT_FIRST_IN')
					begin

						--REINSTATEMENT_ESCO was initated by us so don't set to REINSTATEMENT first for the account_status_log audit trail
						if @current_account_status not in('REINSTATEMENT_ESCO', 'REINSTATEMENT_PENDING')
							begin

							update a set
								account_status_id = 25 --REINSTATEMENT
							from account a
							join account_status s on s.account_status_id = a.account_status_id
							where a.account_id = @account_id

							end

						update a set
							account_status_id = 1, --ACTIVE

							--start_date = @effective_date,
							--end_date = dateadd(YY,2,@effective_date),--default to a 2 year contract date, this could be move to utility or ESCO
							end_date = dateadd(YY,2,a.[start_date]),
							accept_date = getdate(),
							cancel_date = null,
							utility_cancelled_flag = 0

						from account a
						join account_status s on s.account_status_id = a.account_status_id
						where a.account_id = @account_id

						if @effective_date is not null
						begin
							update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
							from account_action aa where aa.account_action_id = @account_action_id
						end
						else
						begin
							update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id
									,note = 'Effective date is null.'
							from account_action aa where aa.account_action_id = @account_action_id
						end

						execute cds_InsertAccountNote @account_id=@account_id ,@note='Account has been reinstated by request from utility or UI.'

					end

				else
					begin
						update aa set account_action_status_id = @NEEDS_REVIEW_account_action_status_id
								,note = 'Account in wrong status to reinstated per request from utility or UI.'
						from account_action aa where aa.account_action_id = @account_action_id
					end
			end


		if @tran_code = 'CHANGE_RSP'
			begin
				update a set a.need_rate_change_flag = 1
				from account a
				cross join account_action_response_reason rr
				where a.account_id = @account_id
				and rr.reason = replace(@reason,@account_num,'')
				and rr.need_rate_change_flag = 1

				update a set a.need_tax_change_flag = 1
				from account a
				cross join account_action_response_reason rr
				where a.account_id = @account_id
				and rr.reason = replace(@reason,@account_num,'')
				and rr.need_tax_change_flag = 1

				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.request_tracking_num = @request_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.sub_tracking_num = @sub_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
					end

				if @response_code = 'ACCEPTED' and exists (select 1 from account_action aa join change_code cc on aa.change_code_id = cc.change_code_id where aa.response_account_action_id = @account_action_id and cc.code = 'BILLING_TYPE')
					begin
						update a set billing_type_id = bt.billing_type_id, dual_billing_date = null
						from account a
						cross join billing_type bt
						where a.account_id = @account_id
						and bt.code = 'LDC'
					end

				update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
				from account_action aa where aa.account_action_id = @account_action_id
			end

		if @tran_code = 'CERTIFIED_COLLECTIONS_EMAIL_RSP'
			begin
				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.request_tracking_num = @request_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
						and aa.tran_code_id = @CERTIFIED_COLLECTIONS_EMAIL_REQ_tran_code_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then  @RESPONDED_TO_account_action_status_id else aa.account_action_status_id end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where (aa.sub_tracking_num = @sub_tracking_num or aa.account_action_id = nullif(try_convert(int,@sub_tracking_num),0))
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
						and aa.tran_code_id = @CERTIFIED_COLLECTIONS_EMAIL_REQ_tran_code_id

						begin try
							update resp set request_account_action_id = req.account_action_id
							from account_action req
							join account_action resp on req.response_account_action_id = resp.account_action_id
							where resp.account_action_id = @account_action_id
							and resp.request_account_action_id is null
						end try
						begin catch
							set @Error += concat('CK_account_action_response_account_action_id_request_account_action_id constraint violated for account_action_id: ',@account_action_id )
						end catch


						if not exists(select 1
						from account_action resp
						join account_action req on req.response_account_action_id = resp.account_action_id and req.account_action_id = resp.request_account_action_id
						where resp.account_action_id = @account_action_id )
						begin
							set @Error += concat('fatal error occured: req.response_account_action_id <> resp.account_action_id XOR req.account_action_id <> resp.request_account_action_id for account_action_id: ', @account_action_id)
						end
					end
				if @Error = ''
				begin
					if @response_code = 'ACCEPTED'
						begin
							update ai set certified_collections_email_receipt_date = @tran_date
							from account_action req
							join account_action_account_invoice aaai on aaai.account_action_id = req.account_action_id
							join account_invoice ai on ai.account_invoice_id = aaai.account_invoice_id
							where req.response_account_action_id = @account_action_id
							and certified_collections_email_receipt_date is null
						end

					if @response_code = 'REJECTED'
						begin
							select @to_email_csv_list = req.to_email
							from account_action resp
							join account_action req on req.response_account_action_id = resp.account_action_id
							where resp.account_action_id = @account_action_id

							insert into #email_list (email_sent)
							select Item
							from dbo.cds_fn_split(@to_email_csv_list,',')
							where Item <> ''


							-- GET all rejected response emails
							update el set email_responded_to = other_resp.to_email
							from account_action resp
							join account_action other_resp on other_resp.request_account_action_id = resp.request_account_action_id and other_resp.response_code_id = resp.response_code_id -- will always be rejected
							join #email_list el on el.email_sent = other_resp.to_email
							where resp.account_action_id = @account_action_id


							if (select count(*) from #email_list l where email_responded_to is not null) = (select count(*) from #email_list e )
							begin
								update ai set certified_collections_email_receipt_date = null
								from account_action req
								join account_action_account_invoice aaai on aaai.account_action_id = req.account_action_id
								join account_invoice ai on ai.account_invoice_id = aaai.account_invoice_id
								where req.response_account_action_id = @account_action_id
								and ai.certified_collections_email_receipt_date is not null
								and @tran_date between ai.certified_collections_email_receipt_date and dateadd(day, @max_days_certified_collections_email_receipt_date,ai.certified_collections_email_receipt_date) --rejection window closes after 4 days.
							end
						end

					update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
					from account_action aa where aa.account_action_id = @account_action_id

				end
				else
				begin
					update aa set process_date = getdate(), account_action_status_id = @NEEDS_REVIEW_account_action_status_id,note = @Error
					from account_action aa where aa.account_action_id = @account_action_id
				end
			select @Error = '', @to_email_csv_list = null
			end

		if @tran_code = 'SUSPENSION_RSP'
			begin
				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.request_tracking_num = @request_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then  @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						join tran_code tc on tc.tran_code_id = aa.tran_code_id 
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.request_tracking_num = @sub_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
					and tc.code = 'SUSPENSION_REQ'
					end

				if @response_code = 'ACCEPTED'
					begin
						update a set suspension_date = isnull(@effective_date,@tran_date) , account_suspension_status_id = @SUSPENDED_account_suspension_status_id
						from account_action req
						join account a on a.account_id = req.account_id
						where req.account_action_id = @account_action_id
						and a.account_suspension_status_id <> @SUSPENDED_account_suspension_status_id
					end

/*				if @response_code = 'REJECTED'
					begin
					end
*/
				update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
				from account_action aa where aa.account_action_id = @account_action_id
			end

		if @tran_code = 'UNSUSPEND_RSP'
			begin
				if @use_account_action_request_tracking_num_for_reponse_flag = 1
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.request_tracking_num = @request_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
					end
				else
					begin
						update aa set aa.response_account_action_id = @account_action_id, account_action_status_id = case @response_code when 'ACCEPTED' then  @RESPONDED_TO_account_action_status_id when 'REJECTED' then isnull(rr.rejected_account_action_status_id, @NEEDS_REVIEW_account_action_status_id)  end
						from account_action aa
						left join account_action_response_reason rr on rr.reason = replace(@reason,@account_num,'')
						where aa.request_tracking_num = @sub_tracking_num
						and aa.account_id = @account_id
						and aa.account_action_id <> @account_action_id
					end

				if @response_code = 'ACCEPTED'
					begin

						update a set account_suspension_status_id = @OPEN_account_suspension_status_id
						from account_action req
						join account a on a.account_id = req.account_id
						where req.account_action_id = @account_action_id
						and a.account_suspension_status_id = @SUSPENDED_account_suspension_status_id
					end

/*				if @response_code = 'REJECTED'
					begin
					end
*/
				update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
				from account_action aa where aa.account_action_id = @account_action_id
			end

		if @tran_code = 'CHANGE_REQ'
			begin
				if ((charindex('[start_date]',@change_value) > 0 or charindex('[end_date]',@change_value) > 0))
					begin
						if charindex('[start_date]',@change_value) > 0
							begin
								set @start = charindex('[start_date]',@change_value) + 16
								set @length = charindex('''',@change_value,@start) - @start
								set @change_date = substring(@change_value,@start,@length)
								exec cds_UpdateAccountServicePeriod @account_id = @account_id, @effective_date = @change_date, @start_flag = 1, @change_flag = 1
							end

						if charindex('[end_date]',@change_value) > 0
							begin
								set @start = charindex('[end_date]',@change_value) + 14
								set @length = charindex('''',@change_value,@start) - @start
								set @change_date = substring(@change_value,@start,@length)
								exec cds_UpdateAccountServicePeriod @account_id = @account_id, @effective_date = @change_date, @start_flag = 0, @change_flag = 1
							end
					end
				if charindex('[cust_id]', @change_value) > 0 and @change_code in ('CUST_ID_SPLIT', 'CUST_ID_MERGE')
				begin
					set @change_date = @effective_date
					set @start = charindex('[cust_id]',@change_value) + 13
					set @length = charindex('''',@change_value,@start) - @start
					set @destination_cust_id =  try_convert(int,substring(@change_value,@start,@length))
					if @destination_cust_id is null
					begin
						set @Error = 'cust_id is null.'
					end
				end
				if exists(select 1 from cust_account where account_id = @account_id and @effective_date <= [start_date]) and @change_code not in ('UTILITY_ANNUAL_USAGE')
				begin
					set @Error = 'another cust has a cust_account.start_date that overlaps this @effective_date for this @account_id.'
				end
				if @change_code in ('CUST_ID_MERGE')
				begin
					set @cust_merge_flag = 1
				end
				if @cust_merge_flag = 1
				begin
					set @source_cust_id = (select cust_id from account a where account_id = @account_id)
					exec cds_CustMergeUpdateChildren @source_cust_id = @source_cust_id, @target_cust_id = @destination_cust_id, @Error = @RemoteError output
					if @RemoteError <> ''
					begin
						set @Error = @RemoteError
						update aa set account_action_status_id = @NEEDS_REVIEW_account_action_status_id
						,note = @Error
						from account_action aa where aa.account_action_id = @account_action_id

					end
				end
				if @Error = ''
				begin
					begin try
						if @change_code in ('CUST_ID_SPLIT','CUST_ID_MERGE')
						begin
							update ca set end_date = dateadd(day,-1,@effective_date)
							from cust_account ca
							where account_id = @account_id and end_date is null

							insert into cust_account (cust_id, account_id, [start_date], account_name)
							select @destination_cust_id, @account_id, @effective_date, @account_name
							update a set bank_id = null from cds.dbo.account a where account_id = @account_id

						end
						if @Error = ''
						begin
							begin try
								set @change_value = 'update a set ' + dbo.cds_fn_ConvertUpperToCamelCase(@change_value) + char(10) + '--select *' + char(10) + 'from account a where account_id = ' + convert(varchar,@account_id)
								--print @change_value
								exec (@change_value)
							end try
							begin catch
								set @Error = isnull(error_message(),'change value update failed')
							end catch
						end
						if @Error = '' and @change_code in ('CUST_ID_SPLIT','CUST_ID_MERGE')
						begin
							exec cds_EndAccountBankContract @account_id = @account_id, @error = @RemoteError output
							set @Error = isnull(nullif(@RemoteError,'cds_EndAccountBankContract returned null error'), @Error)
						end
						if @Error = ''
						begin
							if @change_code = 'START_DATE' and @reason is not null and exists (select * from file_type where file_type_id = @file_type_id and code = 'FROM_AXPO')
							begin
								update a set account_status_id = s2.account_status_id, cancel_reason_id = isnull(rr.cancel_reason_id,a.cancel_reason_id)
								from account a
								join account_status s on a.account_status_id = s.account_status_id
								left join account_action_response_reason rr on rr.reason = replace(replace(@reason,@account_num,''),'_',' ')
								cross join account_status s2
								where a.account_id = @account_id
								and s.code in ('ACTIVE','ENROLL_SENT')
								and s2.code = 'ENROLL_RESCIND_PENDING'
							end

							update a set end_date = [start_date]
							from account a
							where a.account_id = @account_id
							and end_date < [start_date]

							update a set a.end_date = dateadd(year,2,[start_date])
							from account a
							where account_id = @account_id
							and account_status_id = 1 --ACTIVE
							and end_date < dateadd(year,2,[start_date])

							if @change_code = 'BILLING_TYPE'
							begin
								update account set dual_billing_date = @change_date
								where account_id = @account_id
							end
						end
						if @Error = ''
						begin
							update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
							from account_action aa where aa.account_action_id = @account_action_id
						end
						else
						begin
							update aa set account_action_status_id = @NEEDS_REVIEW_account_action_status_id
							,note = @Error
							from account_action aa where aa.account_action_id = @account_action_id
						end
					end try
					begin catch
						EXECUTE dba_InsertProcError 'cds_ProcessAccountAction', 'update account'

						update aa set account_action_status_id = @NEEDS_REVIEW_account_action_status_id
								,note = 'Change request update failed.'
						from account_action aa where aa.account_action_id = @account_action_id
						set @Error = error_message()
					end catch
				end
				else
				begin
					update aa set account_action_status_id = @NEEDS_REVIEW_account_action_status_id
					,note = @Error
					from account_action aa where aa.account_action_id = @account_action_id
				end
			end

		if @tran_code = 'ADVANCE_REQ'
			begin
				update a set dual_billing_date = @effective_date
				from account a
				where a.account_id = @account_id

				update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
				from account_action aa where aa.account_action_id = @account_action_id
			end

		if @tran_code = 'ENROLL_RESCIND_RSP'
			begin
				if @response_code = 'ACCEPTED'
					begin
						update a set account_status_id = s.account_status_id, end_date = a.[start_date], a.utility_cancelled_flag = 0
						from account a
						cross join account_status s
						where a.account_id = @account_id
						and s.code = 'CANCELLED'
					end

				update aa set process_date = getdate(), account_action_status_id = 4--PROCESSED
				from account_action aa where aa.account_action_id = @account_action_id
			end

		set @i += 1
	end

drop table #t
go

