
CREATE procedure [dbo].[ord_ValidateOrdAccount] @ord_account_id int = null, @ErrorReturned varchar(max) = null output 
as

/* 
declare @ErrorReturned varchar(100)
exec ord_ValidateOrdAccount @ord_account_id = 213307, @ErrorReturned = @ErrorReturned output
select @ErrorReturned 
*/

declare @single_account_flag bit = 0

if @ord_account_id is not null
	begin
		set @single_account_flag = 1
	end

--If the control is over an hour old bypass it
if exists (select * from cds_control where ord_account_status_SP_run_date > dateadd(hour,-1,getdate())) and @single_account_flag = 0
	begin
		raiserror('ord_account_status_SP_run_date is too recent to run this SP',11,-1);
		return 0;
	end

if @single_account_flag = 0
	begin
		update cds_control set ord_account_status_SP_run_date = getdate()
	end

declare @ProcName varchar(100), @Process varchar(1000), @Error varchar(max)

set @ProcName = 'ord_ValidateOrdAccount'

declare @emp_id int, @account_note_type_id int, @ord_account_status_id_SENT_ESCO int, @ord_account_status_id_DUPLICATE_NEW int, @UpdateOrdAccountFlag bit = 0, @DataErrorFlag bit = 0,
	@ord_account_status_id_REVIEW_NEW int, @ord_account_status_id int, @ord_account_error_type_id_SEND_ESCO int, @SingleAccountFlag bit = 0

declare @zone_req_flag bit, @lp_req_flag bit, @strata_req_flag bit, @program_code_req_flag bit, @ord_account_status_id_REVIEW int, @CustError varchar(max)

declare @ord_account_error_desc_id int, @ord_account_error_desc_id_DUPLICATE int, @ord_account_error_desc_id_ALREADY_GREEN int, @ord_account_status_id_SEND_CUST int, @ord_account_status_id_SEND_ESCO int

select @ord_account_error_desc_id_DUPLICATE = ord_account_error_desc_id from ord_account_error_desc where code = 'DUPLICATE'
select @ord_account_error_desc_id_ALREADY_GREEN = ord_account_error_desc_id from ord_account_error_desc where code = 'ALREADY_GREEN'

select @ord_account_status_id_DUPLICATE_NEW = ord_account_status_id from ord_account_status where code = 'DUPLICATE_NEW'
select @ord_account_status_id_REVIEW_NEW = ord_account_status_id from ord_account_status where code = 'REVIEW_NEW'
select @ord_account_status_id_REVIEW = ord_account_status_id from ord_account_status where code = 'REVIEW'
select @ord_account_status_id_SEND_CUST = ord_account_status_id from ord_account_status where code = 'SEND_CUST'
select @ord_account_status_id_SEND_ESCO = ord_account_status_id from ord_account_status where code = 'SEND_ESCO'
select @ord_account_error_type_id_SEND_ESCO = ord_account_error_type_id from ord_account_error_type where code = 'SEND_ESCO'


if @ord_account_id is not null
	begin
		set @SingleAccountFlag = 1
	end

update oa set verif_date = c.signed_date
from ord_account oa
join [contract] c on oa.contract_id = c.contract_id
where oa.verif_date is null
and c.signed_date is not null

--Set ord_account record to SEND_CUST if all CUST data is not set
update oa set ord_account_status_id = @ord_account_status_id_SEND_CUST
from ord_account oa
join [contract] c on oa.contract_id = c.contract_id
join ord_cust oc on oa.ord_cust_id = oc.ord_cust_id
where oa.ord_account_status_id = @ord_account_status_id_SEND_ESCO
and not (oa.bank_type_id is not null
	and nullif(oa.bank_account,'') is not null
	and oc.bank_reg_key is not null
	and c.signed_date is not null)

--Set ord_account record to SEND_ESCO if all CUST data is set
update oa set ord_account_status_id = @ord_account_status_id_SEND_ESCO
from ord_account oa
join [contract] c on oa.contract_id = c.contract_id
join ord_cust oc on oa.ord_cust_id = oc.ord_cust_id
where oa.ord_account_status_id = @ord_account_status_id_SEND_CUST
and oa.bank_type_id is not null
and nullif(oa.bank_account,'') is not null
and oc.bank_reg_key is not null
and c.signed_date is not null

select distinct oa.utility_id, oa.esco_id, oa.commodity_id, oa.account_num
into #NotResalable
from ord_account oa
join ord_cust oc on oc.ord_cust_id = oa.ord_cust_id
join ord_account_status	os on os.ord_account_status_id = oa.ord_account_status_id
join ord_sale_type st on st.ord_sale_type_id = oa.ord_sale_type_id
where os.resalable_flag = 0
and os.code not in('SEND_ESCO', 'SEND_CUST', 'NEW')
and st.green_upgrade_flag = 0
and (@ord_account_id is null or exists (select 1 
										from ord_account oa2 
										join ord_sale_type st2 on st2.ord_sale_type_id = oa2.ord_sale_type_id
										where st2.green_upgrade_flag = 0											
										and oa2.utility_id = oa.utility_id and oa2.esco_id = oa.esco_id and oa2.commodity_id = oa.commodity_id and oa2.account_num = oa.account_num and oa2.ord_account_id = @ord_account_id ))

create index IX_NotResalable on #NotResalable (account_num, utility_id, esco_id, commodity_id)

select distinct oa.utility_id, oa.esco_id, oa.commodity_id, oa.account_num
into #NotResalableGreen
from ord_account oa
join ord_cust oc on oc.ord_cust_id = oa.ord_cust_id
join ord_account_status	os on os.ord_account_status_id = oa.ord_account_status_id
join ord_account_pay_status ps on ps.ord_account_pay_status_id = oa.ord_account_pay_status_id
join ord_sale_type st on st.ord_sale_type_id = oa.ord_sale_type_id
where os.resalable_flag = 0
and os.code not in('SEND_ESCO', 'SEND_CUST', 'NEW')
and st.green_flag = 1
and ps.code <> 'GREEN_DOWNGRADE'
and (@ord_account_id is null or exists (select 1 from ord_account oa2 where oa2.utility_id = oa.utility_id and oa2.esco_id = oa.esco_id and oa2.commodity_id = oa.commodity_id and oa2.account_num = oa.account_num and oa2.ord_account_id = @ord_account_id ))

create index IX_NotResalableGreen on #NotResalableGreen (account_num, utility_id, esco_id, commodity_id)

declare
	@OrdAccount_account_id int,
	@id int,
	@utility_id int,
	@commodity_id int,
	@esco_id int,
	@cust_id int,
	@account_status_id int,
	@facility_id int,
	@csr_id int,
	@cancel_reason_id int,
	@language_id int,
	@account_date date,
	@welcome_letter_date date,
	@accept_date date,
	@verif_date datetime,
	@verif_num varchar(20),
	@annual_usage int,
	@account_num varchar(50),
	@account_name varchar(100),
	@address varchar(100),
	@city varchar(100),
	@state_id int,
	@zip varchar(100),
	@bill_account_name varchar(100),
	@bill_address varchar(100),
	@bill_city varchar(100),
	@bill_state_id int,
	@bill_zip varchar(100),
	@zone varchar(1),
	@load_profile varchar(10),
	@strata int,
	@pool_code varchar(50),
	@rate_class varchar(50),
	@tax_district varchar(50),
	@program_code varchar(50),
	@tax_exempt_flag bit,
	@budget_billing_flag bit,
	@tax_rate decimal(18, 6),
	@cancel_fee decimal(18, 2),
	@crg_LDCaccountNum varchar(50),
	@crg_AccntRecNum varchar(50),
	@crg_AccntSeqNum int,
	@crg_AcceptanceErr varchar(3),
	@inserted_date datetime,
	@inserted_by varchar(50),
	@updated_date datetime,
	@updated_by varchar(50),
	@signup_date date,
	@margin_type_id int,
	@retention_flag bit,
	@winback_flag bit,
	@green_upgrade_flag bit,
	@market varchar(50),
	@por_flag bit,
	@DuplicateSaleFlag bit,
	@DuplicateGreenSaleFlag bit,
	@account_num_length_min int,
	@account_num_length_max int,
	@account_num_prefix_val varchar(100),
	@utility_zip_id int,
	@ord_cust_id int,
	@contract_id int,
	@gas_use_type_id int,
	@meter_num varchar(100)


create table #account(
	id int IDENTITY(1,1) NOT NULL Primary key,
	ord_account_id int NOT NULL,
	OrdAccount_account_id int NULL,
	utility_id int NULL,
	commodity_id int NULL,
	esco_id int NULL,
	cust_id int NULL,
	account_status_id int NOT NULL,
	facility_id int NULL,
	csr_id int NULL,
	cancel_reason_id int NULL,
	language_id int NULL,
	account_date date NULL,
	welcome_letter_date date NULL,
	accept_date date NULL,
	verif_date datetime NULL,
	verif_num varchar(20) NULL,
	annual_usage int NULL,
	account_num varchar(50) NULL,
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
	[zone] varchar(1) NULL,
	load_profile varchar(10) NULL,
	strata int NULL,
	pool_code varchar(50) NULL,
	rate_class varchar(50) NULL,
	tax_district varchar(50) NULL,
	program_code varchar(50) NULL,
	tax_exempt_flag bit NULL,
	budget_billing_flag bit NOT NULL,
	tax_rate decimal(18, 6) NOT NULL,
	cancel_fee decimal(18, 2) NULL,
	crg_LDCaccountNum varchar(50) NULL,
	crg_AccntRecNum varchar(50) NULL,
	crg_AccntSeqNum int NULL,
	crg_AcceptanceErr varchar(3) NULL,
	inserted_date datetime NULL,
	inserted_by varchar(50) NULL,
	updated_date datetime NULL,
	updated_by varchar(50) NULL,
	signup_date date NULL,
	margin_type_id int NOT NULL,
	retention_flag bit NOT NULL,
	winback_flag bit NOT NULL,
	green_upgrade_flag bit NOT NULL,
	market varchar(50), 
	por_flag bit,
	DuplicateSaleFlag bit NOT NULL,
	DuplicateGreenSaleFlag bit NOT NULL,
	green_flag bit NOT NULL,
	account_num_length_min int null,
	account_num_length_max int null,
	account_num_prefix_val varchar(100) null,
	utility_zip_id int null,
	ord_cust_id int null,
	contract_id int null,
	gas_use_type_id int null,
	meter_num varchar(100) null
	)

insert into #account
	(
	ord_account_id,
	OrdAccount_account_id,
	utility_id,
	commodity_id,
	esco_id,
	cust_id,
	account_status_id,
	facility_id,
	csr_id,
	cancel_reason_id,
	language_id,
	account_date,
	welcome_letter_date,
	accept_date,
	verif_date,
	verif_num,
	annual_usage,
	account_num,
	account_name,
	[address],
	city,
	state_id,
	zip,
	bill_account_name,
	bill_address,
	bill_city,
	bill_state_id,
	bill_zip,
	[zone],
	load_profile,
	strata,
	pool_code,
	rate_class,
	tax_district,
	program_code,
	tax_exempt_flag,
	budget_billing_flag,
	tax_rate,
	cancel_fee,
	crg_LDCaccountNum,
	crg_AccntRecNum,
	crg_AccntSeqNum,
	crg_AcceptanceErr,
	inserted_date,
	inserted_by,
	updated_date,
	updated_by,
	signup_date,
	margin_type_id,
	retention_flag,
	winback_flag,
	green_upgrade_flag,
	market,
	por_flag,
	DuplicateSaleFlag,
	DuplicateGreenSaleFlag,
	green_flag,
	account_num_length_min,
	account_num_length_max,
	account_num_prefix_val,
	utility_zip_id,
	ord_cust_id,
	contract_id,
	gas_use_type_id,
	meter_num
	)
select
	oa.ord_account_id,
	oa.account_id 'OrdAccount_account_id',
	oa.utility_id
	,oa.commodity_id
	,oa.esco_id
	,oc.cust_id
	, 10 'account_status_id' --SENT_ESCO
	,st.facility_id
	,oa.csr_id
	,oa.cancel_reason_id
	,oa.language_id
	,getdate() 'account_date'
	,oa.welcome_letter_date
	,oa.accept_date
	,oa.verif_date
	,oa.verif_num
	,oa.annual_usage
	,oa.account_num
	,oa.account_name
	,oa.[address]
	,oa.city
	,oa.state_id
	,oa.zip
	,oa.bill_account_name
	,oa.bill_address
	,oa.bill_city
	,oa.bill_state_id
	,oa.bill_zip
	,oa.[zone]
	,oa.load_profile
	,oa.strata
	,oa.pool_code
	,oa.rate_class
	,oa.tax_district
	,oa.program_code
	,oa.tax_exempt_flag
	,oa.budget_billing_flag
	,isnull(oa.tax_rate, 0) 'tax_rate'
	,isnull(oa.cancel_fee, 0) 'cancel_fee'
	,oa.crg_LDCaccountNum
	,oa.crg_AccntRecNum
	,oa.crg_AccntSeqNum
	,oa.crg_AcceptanceErr
	, getdate() 'inserted_date'
	,'CDS_Order' 'inserted_by'
	,getdate() 'updated_date'
	,'CDS_Order' 'updated_by'
	,oa.signup_date
	,1 'margin_type_id' --RETAIL
	,st.retention_flag
	,st.winback_flag
	,st.green_upgrade_flag
	,m.code 'market'
	,euc.por_flag
	,case when r.utility_id is null or os.code = 'UPDATE_ESCO' then 0 else 1 end 'DuplicateSaleFlag'
	,case when rg.utility_id is null or os.code = 'UPDATE_ESCO' then 0 else 1 end 'DuplicateGreenSaleFlag'
	,st.green_flag
	,anv.account_num_length_min
	,anv.account_num_length_max
	,anv.account_num_prefix_val
	,uz.utility_zip_id
	,oa.ord_cust_id
	,oa.contract_id
	,oa.gas_use_type_id
	,oa.meter_num
from ord_account oa
join ord_cust oc on oc.ord_cust_id = oa.ord_cust_id
join utility u on u.utility_id = oa.utility_id
join market m on m.market_id = u.market_id
join esco e on e.esco_id = oa.esco_id
join esco_utility_commodity euc on euc.esco_id = oa.esco_id and euc.utility_id = oa.utility_id and euc.commodity_id = oa.commodity_id
join ord_account_status os on os.ord_account_status_id = oa.ord_account_status_id
join ord_sale_type st on st.ord_sale_type_id = oa.ord_sale_type_id
left join #NotResalable r on r.utility_id = oa.utility_id and r.esco_id = oa.esco_id and r.commodity_id = oa.commodity_id and r.account_num = oa.account_num
left join account_num_val anv on oa.commodity_id = anv.commodity_id and oa.utility_id = anv.utility_id
left join utility_zip uz on left(oa.zip,5) = left(uz.zip,5)
left join #NotResalableGreen rg on rg.utility_id = oa.utility_id and rg.esco_id = oa.esco_id and rg.commodity_id = oa.commodity_id and rg.account_num = oa.account_num
where os.code in('SEND_CUST', 'NEW', 'UPDATE_ESCO')
and (oa.ord_account_id = @ord_account_id or @ord_account_id is null)
order by oa.ord_account_id

create index IX_OrdAccountID ON #account (account_num, utility_id, commodity_id, esco_id, ord_account_id)
create index IX_OrdAccountID2 ON #account (ord_account_id)

--select a.DuplicateSaleFlag, *
update a set a.DuplicateSaleFlag = 1
from #account a
join   (select a1.account_num, a1.utility_id, a1.commodity_id, a1.esco_id, max(a1.ord_account_id) ord_account_id, count(*) as cnt
              from #account a1
              join #account a2 on a1.account_num = a2.account_num and a1.utility_id = a2.utility_id and a1.commodity_id = a2.commodity_id and a1.esco_id = a2.esco_id
              where a1.DuplicateSaleFlag = 0
              and a1.DuplicateGreenSaleFlag = 0
              and a1.green_upgrade_flag = 0
              group by a1.account_num, a1.utility_id, a1.commodity_id, a1.esco_id
              having count(*) > 1
       ) a3 on a3.account_num = a.account_num and a3.utility_id = a.utility_id and a3.commodity_id = a.commodity_id and a3.esco_id = a.esco_id and a3.ord_account_id <> a.ord_account_id
	    where a.green_upgrade_flag = 0

update a set a.DuplicateSaleFlag = 1
from #account a
join   (select a1.account_num, a1.utility_id, a1.commodity_id, a1.esco_id, max(a1.ord_account_id) ord_account_id, count(*) as cnt
              from #account a1
              join #account a2 on left(a1.account_num,14) = left(a2.account_num,14) and a1.utility_id = a2.utility_id and a1.commodity_id = a2.commodity_id and a1.esco_id = a2.esco_id
              where a1.DuplicateSaleFlag = 0
              and a1.DuplicateGreenSaleFlag = 0
              and a1.green_upgrade_flag = 0
			  and a1.market = 'IT'
              group by a1.account_num, a1.utility_id, a1.commodity_id, a1.esco_id
              having count(*) > 1
       ) a3 on left(a3.account_num,14) = left(a.account_num,14) and a3.utility_id = a.utility_id and a3.commodity_id = a.commodity_id and a3.esco_id = a.esco_id and a3.ord_account_id <> a.ord_account_id
	    where a.green_upgrade_flag = 0

--select a.DuplicateGreenSaleFlag, *
update a set a.DuplicateGreenSaleFlag = 1
from #account a
join   (select a1.account_num, a1.utility_id, a1.commodity_id, a1.esco_id, max(a1.ord_account_id) ord_account_id, count(*) as cnt
              from #account a1
              join #account a2 on a1.account_num = a2.account_num and a1.utility_id = a2.utility_id and a1.commodity_id = a2.commodity_id and a1.esco_id = a2.esco_id
              where a1.DuplicateSaleFlag = 0
              and a1.DuplicateGreenSaleFlag = 0
              and a1.green_upgrade_flag = 1
              group by a1.account_num, a1.utility_id, a1.commodity_id, a1.esco_id
              having count(*) > 1
       ) a3 on a3.account_num = a.account_num and a3.utility_id = a.utility_id and a3.commodity_id = a.commodity_id and a3.esco_id = a.esco_id and a3.ord_account_id <> a.ord_account_id
	   where a.green_upgrade_flag = 1


declare @i int, @total int

set @i = 1
select @total = count(*) from #account

while @i <= @total
	begin
		set @ord_account_status_id = null
		set @UpdateOrdAccountFlag = 0
		set @DataErrorFlag = 0
		set @Error = ''
		set @CustError = null

		select
			@ord_account_id = ord_account_id, 
			@OrdAccount_account_id = OrdAccount_account_id,
			@utility_id = utility_id,
			@commodity_id = commodity_id,
			@esco_id = esco_id,
			@cust_id = cust_id,
			@account_status_id = account_status_id,
			@facility_id = facility_id,
			@csr_id = csr_id,
			@cancel_reason_id = cancel_reason_id,
			@language_id = language_id,
			@account_date = account_date,
			@welcome_letter_date = welcome_letter_date,
			@accept_date = accept_date,
			@verif_date = verif_date,
			@verif_num = verif_num,
			@annual_usage = annual_usage,
			@account_num = account_num,
			@account_name = account_name,
			@address = [address],
			@city = city,
			@state_id = state_id,
			@zip = zip,
			@bill_account_name = bill_account_name,
			@bill_address = bill_address,
			@bill_city = bill_city,
			@bill_state_id = bill_state_id,
			@bill_zip = bill_zip,
			@zone = [zone],
			@load_profile = load_profile,
			@strata = strata,
			@pool_code = pool_code,
			@rate_class = rate_class,
			@tax_district = tax_district,
			@program_code = program_code,
			@tax_exempt_flag = tax_exempt_flag,
			@budget_billing_flag = budget_billing_flag,
			@tax_rate = tax_rate,
			@cancel_fee = cancel_fee,
			@crg_LDCaccountNum = crg_LDCaccountNum,
			@crg_AccntRecNum = crg_AccntRecNum,
			@crg_AccntSeqNum = crg_AccntSeqNum,
			@crg_AcceptanceErr = crg_AcceptanceErr,
			@inserted_date = inserted_date,
			@inserted_by = inserted_by,
			@updated_date = updated_date,
			@updated_by = updated_by,
			@signup_date = signup_date,
			@margin_type_id = margin_type_id,
			@retention_flag = retention_flag,
			@winback_flag = winback_flag,
			@green_upgrade_flag = green_upgrade_flag,
			@market = market,
			@por_flag = por_flag,
			@DuplicateSaleFlag = DuplicateSaleFlag,
			@DuplicateGreenSaleFlag = DuplicateGreenSaleFlag,
			@ord_cust_id = ord_cust_id,
			@account_num_prefix_val = account_num_prefix_val,
			@account_num_length_min = account_num_length_min,
			@account_num_length_max = account_num_length_max,
			@utility_zip_id = utility_zip_id,
			@contract_id = contract_id,
			@gas_use_type_id = gas_use_type_id,
			@meter_num = meter_num
		from #account
		where id = @i

		--Duplicate Sale
		if @DuplicateSaleFlag = 1 and @green_upgrade_flag = 0
			begin
				set @DataErrorFlag = 1
				set @ord_account_error_desc_id = @ord_account_error_desc_id_DUPLICATE
				select  @Error += '-Duplicate Sale'
				set @ord_account_status_id = @ord_account_status_id_DUPLICATE_NEW
			end 		
		
		--Duplicate Green Upgrade Sale
		if @DuplicateGreenSaleFlag = 1 and @green_upgrade_flag = 1
			begin
				set @DataErrorFlag = 1
				set @ord_account_error_desc_id = @ord_account_error_desc_id_DUPLICATE
				select  @Error += '-Duplicate Green Upgrade Sale'
				set @ord_account_status_id = @ord_account_status_id_DUPLICATE_NEW
			end 	

		select @zone_req_flag = zone_req_flag, @lp_req_flag = lp_req_flag, @strata_req_flag = strata_req_flag, @program_code_req_flag = program_code_req_flag
		from utility
		where utility_id = @utility_id

		if @contract_id is not null
			begin
				--utility_rate_class_id not set at contract for RATE_CLASS utility
				select @DataErrorFlag = 1, @Error += '-Contract rate class is null'
				from contract_item ci
				cross join esco_utility_commodity euc
				join utility_bill_type bt on euc.utility_bill_type_id = bt.utility_bill_type_id
				where ci.utility_rate_class_id is null
				and ci.contract_id = @contract_id
				and euc.esco_id = @esco_id
				and euc.utility_id = @utility_id
				and euc.commodity_id = @commodity_id
				and bt.code like '%RATE_CLASS%'

				--bill_rate not set at contract for non-RATE_CLASS utility
				select @DataErrorFlag = 1, @Error += '-Contract rate is null'
				from contract_item ci
				cross join esco_utility_commodity euc
				join utility_bill_type bt on euc.utility_bill_type_id = bt.utility_bill_type_id
				where ci.bill_rate is null
				and ci.contract_id = @contract_id
				and euc.esco_id = @esco_id
				and euc.utility_id = @utility_id
				and euc.commodity_id = @commodity_id
				and bt.code not like '%RATE_CLASS%'
			end

		--if @green_upgrade_flag = 0--no need to validate the below if just a green upgrade 
		--	begin
		--		--Zone (and zone length)
		--		if len(@zone) > 1
		--			begin
		--				set @DataErrorFlag = 1
		--				select  @Error += '-Zone Greater than 1 Char'
		--			end 
                        
		--		if @zone_req_flag = 1 and @zone is null and @commodity_id = 2 --elec
		--			begin
		--				set @DataErrorFlag = 1
		--				select @Error += '-Zone is null but required'
		--			end

		--		if (select count(*) from utility_zone z where z.utility_id = @utility_id and z.commodity_id = @commodity_id) > 0 and
		--			(select count(*) from utility_zone z where z.utility_id = @utility_id and z.commodity_id = @commodity_id and z.zone = @zone) = 0
		--			begin
		--				set @DataErrorFlag = 1
		--				select @Error += '-"' + isnull(@zone,'NULL') + '"  is not valid Zone'
		--			end

		--		--Load Profile
		--		if @lp_req_flag = 1 and @load_profile is null and @commodity_id = 2 --elec
		--			begin
		--				set @DataErrorFlag = 1
		--				select @Error += '-Load Profile is null but required'
		--			end

		--		--Strata
		--		if @strata_req_flag = 1 and @strata is null and @commodity_id = 2 --elec
		--			begin
		--				set @DataErrorFlag = 1
		--				select @Error += '-Strata is null but required'
		--			end

		--		--Program Code
		--		if @program_code_req_flag = 1 and @program_code is null
		--			begin
		--				set @DataErrorFlag = 1
		--				select @Error += '-Progarm Code is null but required'
		--			end
		--		--
		--		--decided not needed on 5/11/2015
		--		----Rate Class
		--		--if @rate_class is null and @utility_id in (1,4,5) --CHUD, NFG, NIMO
		--		--	begin
		--		--		set @DataErrorFlag = 1
		--		--		select @Error += '-Rate Class is null but required'
		--		--	end

		--		--Pool Code
		--		if @pool_code is null and @utility_id = 6 and @commodity_id = 1 --NYSEG --gas
		--			begin
		--				set @DataErrorFlag = 1
		--				select @Error += '-Pool Code is null but required'
		--			end
		--	end
				
		-- Account num prefix 
		if @account_num not like @account_num_prefix_val + '%' 
			begin 
				set @DataErrorFlag = 1
				set @ord_account_status_id = @ord_account_status_id_REVIEW
				select @Error += '-Account_num prefix error'
			end 

		-- Account num length  
		if len(@account_num) not between @account_num_length_min and @account_num_length_max
			begin 
				set @DataErrorFlag = 1
				set @ord_account_status_id = @ord_account_status_id_REVIEW
				select @Error += ' -Account_num_length error'	
			end 

		-- Gas account missing gas_use_type_id
		if @gas_use_type_id is null and @commodity_id = 1 --Gas
			begin 
				set @DataErrorFlag = 1
				set @ord_account_status_id = @ord_account_status_id_REVIEW
				select @Error += ' -Gas account missing gas_use_type_id'	
			end 

		-- Gas account missing meter_num
		if @meter_num is null and @commodity_id = 1 --Gas
			begin 
				set @DataErrorFlag = 1
				set @ord_account_status_id = @ord_account_status_id_REVIEW
				select @Error += ' -Gas account missing meter_num'	
			end 	

		--validate ord_cust data
		set @Process = 'Execute ord_ValidateOrdCust'
		begin try				
			execute ord_ValidateOrdCust @ord_cust_id, @CustError output		
		end try
		begin catch
			EXECUTE dba_InsertProcError @ProcName, @Process
		end catch					
		
		--Cust data error
		if @CustError is not null
			begin
				set @DataErrorFlag = 1
				set @Error = @CustError
			end
				
												
		if @DataErrorFlag = 0 and @SingleAccountFlag = 0
			begin

				set @Process = 'UPDATE cds.dbo.ord_account-@ord_account_status_id_SEND_CUST'
				begin try

					select @ord_account_status_id = oa.ord_account_status_id
					from ord_account_status oa
					where oa.ord_account_status_id = @ord_account_status_id_SEND_CUST

					update oa set ord_account_status_id = @ord_account_status_id
					from ord_account oa
					where ord_account_id = @ord_account_id

					exec ord_UpdateOrdAccountPayStatus @ord_account_id = @ord_account_id
				end try
				begin catch
					EXECUTE dba_InsertProcError @ProcName, @Process
				end catch	
			end


		if @DataErrorFlag = 1
			begin	
				if @SingleAccountFlag = 1
					begin
						set @ErrorReturned = @Error
					end
				else
					begin
						insert into ord_account_error (error_date, ord_account_id, error, ord_account_error_type_id, ord_account_error_desc_id)
						select getdate(), @ord_account_id , @Error, @ord_account_error_type_id_SEND_ESCO, @ord_account_error_desc_id

						set @Process = 'UPDATE cds.dbo.ord_account-REVIEW_NEW'
						begin try
							select @ord_account_status_id = oa.ord_account_status_id
							from ord_account_status oa
							where oa.ord_account_status_id = isnull(@ord_account_status_id, @ord_account_status_id_REVIEW_NEW)

							update oa set ord_account_status_id = @ord_account_status_id
							from ord_account oa
							where ord_account_id = @ord_account_id

							exec ord_UpdateOrdAccountPayStatus @ord_account_id = @ord_account_id
						end try
						begin catch
							EXECUTE dba_InsertProcError @ProcName, @Process
						end catch	
					end
			end
		set @i += 1
	end

if @single_account_flag = 0
	begin
		update cds_control set ord_account_status_SP_run_date = null
	end
go

