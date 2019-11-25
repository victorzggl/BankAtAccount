use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter procedure dbo.ord_InsertAccount as

--If the control is over an hour old bypass it
if exists (select * from cds_control where ord_account_status_SP_run_date > dateadd(hour,-1,getdate()))
	begin
		raiserror('ord_account_status_SP_run_date is too recent to run this SP',11,-1);
	end

update cds_control set ord_account_status_SP_run_date = getdate()

declare @ProcName varchar(100), @Process varchar(1000), @Error varchar(max)

set @ProcName = 'ord_InsertAccount'

declare @emp_id int = (select emp_id from emp e where e.emp_num = 3 and e.first_name = 'CDSOrdImport'),
		@ord_account_status_id_SENT_ESCO int = (select ord_account_status_id from ord_account_status where code = 'SENT_ESCO'),
		@ord_account_status_id_DUPLICATE_NEW int = (select ord_account_status_id from ord_account_status where code = 'DUPLICATE_NEW'),
		@UpdateOrdAccountFlag bit = 0,
		@DataErrorFlag bit = 0,
		@ord_account_status_id_REVIEW_NEW int = (select ord_account_status_id from ord_account_status where code = 'REVIEW_NEW'),
		@ord_account_status_id int,
		@ord_account_error_type_id_SEND_ESCO int = (select ord_account_error_type_id from ord_account_error_type where code = 'SEND_ESCO'),
		@ord_account_error_desc_id int,
		@ord_account_error_desc_id_DUPLICATE int = (select ord_account_error_desc_id from ord_account_error_desc where code = 'DUPLICATE'),
		@ord_account_error_desc_id_ALREADY_GREEN int = (select ord_account_error_desc_id from ord_account_error_desc where code = 'ALREADY_GREEN'),
		@today date = getdate(),
		@account_note_type_id_CRG_ACCOUNT_REMARK int = (select account_note_type_id from account_note_type where code = 'CRG_ACCOUNT_REMARK'),
		@account_note_type_id_DATA_PROCESSING int = (select account_note_type_id from account_note_type where code = 'DATA_PROCESSING'),
		@account_status_id_SENT_ESCO int = (select account_status_id from account_status where code = 'SENT_ESCO'),
		@account_status_id_HOLD int = (select account_status_id from account_status where code = 'HOLD'),
		@bank_error varchar(500)

declare
	@ord_account_id int,
	@OrdAccount_account_id int,
	@CDSCust_id int,
	@account_id int,
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
	@cancel_date date,
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
	@crg_AccntRecNum varchar(50),
	@crg_AccntSeqNum int,
	@crg_AcceptanceErr varchar(3),
	@inserted_date datetime,
	@inserted_by varchar(50),
	@updated_date datetime,
	@updated_by varchar(50),
	@signup_date date,
	@green_rate_id int,
	@margin_type_id int,
	@retention_flag bit,
	@winback_flag bit,
	@green_upgrade_flag bit,
	@account_status varchar(50),
	@por_flag bit,
	@esco_account_num varchar(50),
	@tax_district_required_flag bit,
	@same_call_green_upgrade_flag bit,
	@contract_id int,
	@contract_start_date date,
	@cancel_fee_flag bit,
	@ord_account_hold_type_id int,
	@street_part varchar(50),
	@street_part_id int,
	@street_num varchar(50),
	@country_id int,
	@bank_type_id int,
	@cds_bank_account_key varchar(50),
	@bank_account_key varchar(50),
	@personal_tax_num varchar(50),
	@business_tax_num varchar(50),
	@bank_authorization_key varchar(100),
	@bank_account varchar(100),
	@gas_use_type_id int,
	@meter_num varchar(100),
	@document_key varchar(100),
	@utility_sub_id int,
	@bank_account_name varchar(100),
	@bank_contract_id int,
	@signed_date date,
	@signatory_email varchar(255),
	@signatory_name varchar(100),
	@signatory_contact_id int,
	@signatory_personal_tax_num varchar(100)


create table #account(
	id int identity(1,1) NOT NULL primary key,
	ord_account_id int NOT NULL,
	OrdAccount_account_id int NULL,
	CDSCust_id int NULL,
	account_id int NULL,
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
	cancel_date date NULL,
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
	crg_AccntRecNum varchar(50) NULL,
	crg_AccntSeqNum int NULL,
	crg_AcceptanceErr varchar(3) NULL,
	inserted_date datetime NULL,
	inserted_by varchar(50) NULL,
	updated_date datetime NULL,
	updated_by varchar(50) NULL,
	signup_date date NULL,
	green_rate_id int NULL,
	margin_type_id int NOT NULL,
	retention_flag bit NOT NULL,
	winback_flag bit NOT NULL,
	green_upgrade_flag bit NOT NULL,
	account_status varchar(50) NULL,
	por_flag bit NOT NULL,
	esco_account_num varchar(50) NULL,
	tax_district_required_flag bit NOT NULL,
	same_call_green_upgrade_flag bit NULL,
	contract_id int NULL,
	contract_start_date date NULL,
	cancel_fee_flag bit NULL,
	ord_account_hold_type_id int NULL,
	street_part varchar(50) NULL,
	street_part_id int NULL,
	street_num varchar(50) NULL,
	country_id int NOT NULL,
	bank_type_id int NULL,
	cds_bank_account_key varchar(50) NULL,
	bank_account_key varchar(50) NULL,
	personal_tax_num varchar(50) NULL,
	business_tax_num varchar(50) NULL,
	bank_authorization_key varchar(100) NULL,
	bank_account varchar(100) NULL,
	gas_use_type_id int NULL,
	meter_num varchar(100) NULL,
	document_key varchar(100) NULL,
	utility_sub_id int NULL,
	bank_account_name varchar(100) null,
	bank_contract_id int null,
	signatory_email varchar(255) null,
	signatory_name varchar(100) null,
	signatory_personal_tax_num varchar(100) null,
	signatory_contact_id int null
	)

create nonclustered index IX_AccountNumUtilityIDCommodityIDEscoID on #account (account_num, utility_id, commodity_id, esco_id)

insert into #account
	(
	ord_account_id,
	OrdAccount_account_id,
	CDSCust_id,
	account_id,
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
	cancel_date,
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
	crg_AccntRecNum,
	crg_AccntSeqNum,
	crg_AcceptanceErr,
	inserted_date,
	inserted_by,
	updated_date,
	updated_by,
	signup_date,
	green_rate_id,
	margin_type_id,
	retention_flag,
	winback_flag,
	green_upgrade_flag,
	account_status,
	por_flag,
	esco_account_num,
	tax_district_required_flag,
	same_call_green_upgrade_flag,
	contract_id,
	contract_start_date,
	cancel_fee_flag,
	ord_account_hold_type_id,
	street_part,
	street_part_id,
	street_num,
	country_id,
	bank_type_id,
	cds_bank_account_key,
	bank_account_key,
	personal_tax_num,
	business_tax_num,
	bank_authorization_key,
	bank_account,
	gas_use_type_id,
	meter_num,
	document_key,
	utility_sub_id,
	bank_account_name,
	signatory_email,
	signatory_name,
	signatory_personal_tax_num,
	signatory_contact_id
	)
select
	oa.ord_account_id
	,oa.account_id 'OrdAccount_account_id'
	,isnull(a.cust_id,a2.cust_id) 'CDSCust_id'
	,isnull(a.account_id,a2.account_id) 'account_id'
	,oa.utility_id
	,oa.commodity_id
	,oa.esco_id
	,oc.cust_id
	,@account_status_id_SENT_ESCO 'account_status_id'
	,st.facility_id
	,oa.csr_id
	,oa.cancel_reason_id
	,oa.language_id
	,getdate() 'account_date'
	,oa.welcome_letter_date
	,oa.accept_date
	,isnull(a.cancel_date,a2.cancel_date) 'cancel_date'
	,isnull(oa.verif_date,c.signed_date) 'verif_date'
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
	,coalesce(oa.tax_rate, ut.tax_rate, 0) 'tax_rate'
	,oa.cancel_fee 'cancel_fee'
	,oa.crg_AccntRecNum
	,oa.crg_AccntSeqNum
	,oa.crg_AcceptanceErr
	, getdate() 'inserted_date'
	,'CDS_Order' 'inserted_by'
	,getdate() 'updated_date'
	,'CDS_Order' 'updated_by'
	,oa.signup_date
	,case when st.green_flag = 1 and oa.green_downgrade_date is null then gr.green_rate_id else null end 'green_rate_id'
	,1 'margin_type_id' --RETAIL
	,st.retention_flag
	,st.winback_flag
	,st.green_upgrade_flag
	,isnull(s.code,s2.code) 'account_status'
	,oa.por_flag
	,NULL --esco_account_num
	,uc.tax_district_required_flag
	,oa.same_call_green_upgrade_flag
	,c.contract_id
	,isnull(c.[start_date],@today) 'contract_start_date'
	,oa.cancel_fee_flag
	,oa.ord_account_hold_type_id
	,oa.street_part
	,sp.street_part_id
	,oa.street_num
	,oa.country_id
	,oa.bank_type_id
	,oa.cds_bank_account_key
	,oa.bank_account_key
	,upper(oa.personal_tax_num)
	,upper(oa.business_tax_num)
	,oa.bank_authorization_key
	,oa.bank_account
	,oa.gas_use_type_id
	,oa.meter_num
	,c.document_key
	,oa.utility_sub_id
	,oa.bank_account_name
	,c.contract_email signatory_email
	,oct.first_name + ' ' + oct.last_name signatory_name
	,oct.personal_tax_num signatory_personal_tax_num
	,con.contact_id signatory_contact_id
from ord_account oa
join utility u on u.utility_id = oa.utility_id
join ord_account_status os on os.ord_account_status_id = oa.ord_account_status_id
join ord_sale_type st on st.ord_sale_type_id = oa.ord_sale_type_id
join ord_cust oc on oc.ord_cust_id = oa.ord_cust_id
left join utility_green_rate gr on gr.esco_id = oa.esco_id and gr.utility_id = oa.utility_id and gr.commodity_id = oa.commodity_id and cast(oa.verif_date as date) between gr.[start_date] and isnull(gr.end_date,cast(oa.verif_date as date))
join [contract] c on c.contract_id = oa.contract_id
--join ord_verif_status vs on vs.ord_verif_status_id = oa.ord_verif_status_id
--join ord_post_close_status ps on ps.ord_post_close_status_id = oa.ord_post_close_status_id
join utility_commodity uc on uc.utility_id = oa.utility_id and uc.commodity_id = oa.commodity_id
join esco_utility_commodity euc on euc.esco_id = oa.esco_id and euc.utility_id = oa.utility_id and euc.commodity_id = oa.commodity_id
join csr on oa.csr_id = csr.csr_id
left join account a on a.utility_id = oa.utility_id and a.esco_id = oa.esco_id and a.commodity_id = oa.commodity_id and a.account_num = oa.account_num
left join account_status s on s.account_status_id = a.account_status_id
left join account a2 on a2.account_id = oa.account_id
left join account_status s2 on s2.account_status_id = a2.account_status_id
left join street_part sp on sp.name = oa.street_part
left join ord_contact oct on oct.ord_contact_id = c.signatory_ord_contact_id
left join (select cust_id, first_name, last_name, max(contact_id) contact_id from contact group by cust_id, first_name, last_name ) con on con.cust_id = oc.cust_id and con.first_name = oct.first_name and con.last_name = oct.last_name
left join
	(select ut.*
	from utility_tax ut
	join utility_tax_type utt on ut.utility_tax_type_id = utt.utility_tax_type_id
	where utt.code = 'VAT') ut on ut.utility_id = oa.utility_id and ut.commodity_id = oa.commodity_id and ut.facility_id = oa.facility_id

where oa.bank_type_id is not null
and nullif(oa.bank_account,'') is not null
and nullif(oa.bank_account_name,'') is not null
and os.code = 'SEND_ESCO'
and c.signed_date is not null
and euc.cds_active_flag = 1
and csr.test_csr_flag = 0
order by oa.ord_account_id


declare @i int, @total int

set @i = 1
select @total = count(*) from #account

while @i <= @total
	begin
		set @ord_account_status_id = null
		set @UpdateOrdAccountFlag = 0
		set @DataErrorFlag = 0
		set @Error = ''
		set @ord_account_error_desc_id = null
		set @bank_contract_id = null

		select
			@ord_account_id = ord_account_id,
			@OrdAccount_account_id = OrdAccount_account_id,
			@CDSCust_id = CDSCust_id,
			@account_id = account_id,
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
			@cancel_date = cancel_date,
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
			@crg_AccntRecNum = crg_AccntRecNum,
			@crg_AccntSeqNum = crg_AccntSeqNum,
			@crg_AcceptanceErr = crg_AcceptanceErr,
			@inserted_date = inserted_date,
			@inserted_by = inserted_by,
			@updated_date = updated_date,
			@updated_by = updated_by,
			@signup_date = signup_date,
			@green_rate_id = green_rate_id,
			@margin_type_id = margin_type_id,
			@retention_flag = retention_flag,
			@winback_flag = winback_flag,
			@green_upgrade_flag = green_upgrade_flag,
			@account_status = account_status,
			@por_flag = por_flag,
			@tax_district_required_flag = tax_district_required_flag,
			@same_call_green_upgrade_flag = same_call_green_upgrade_flag,
			@contract_id = contract_id,
			@contract_start_date = contract_start_date,
			@cancel_fee_flag = cancel_fee_flag,
			@ord_account_hold_type_id = ord_account_hold_type_id,
			@street_part = street_part,
			@street_part_id = street_part_id,
			@street_num = street_num,
			@country_id = country_id,
			@bank_type_id = bank_type_id,
			@cds_bank_account_key = cds_bank_account_key,
			@bank_account_key = bank_account_key,
			@personal_tax_num = personal_tax_num,
			@business_tax_num = business_tax_num,
			@bank_authorization_key = bank_authorization_key,
			@bank_account = bank_account,
			@gas_use_type_id = gas_use_type_id,
			@meter_num = meter_num,
			@document_key = document_key,
			@utility_sub_id = utility_sub_id,
			@bank_account_name = bank_account_name,
			@signatory_email = signatory_email,
		 	@signatory_name = signatory_name,
		 	@signatory_contact_id = signatory_contact_id,
		 	@signatory_personal_tax_num = signatory_personal_tax_num
		from #account
		where id = @i






	if nullif(@signatory_name,'') is null or nullif(@signatory_personal_tax_num,'') is null
	begin
		set @DataErrorFlag = 1
		--TODO @GregG: PersonalTaxNum at OrdContact this is a required field for x contact types. A hack will be needed until these values are provided.
		select @Error += '-@signatory_name or -@signatory_personal_tax_num is null but required contract signature must match name ord_contact'
	end


	if @signatory_contact_id is null
		begin
			set @DataErrorFlag = 1
			select @Error += '-@signatory_contact_id is null but required contract signature must exist in contact'
		end

	if @bank_contract_id is null and @DataErrorFlag = 0
		begin
			exec cds_InsertBankContract
			 @cust_id = @cust_id,
			 @bank_type_id = @bank_type_id,
			 @bank_account = @bank_account,
			 @bank_account_name = @bank_account_name,
			 @document_key = @document_key,
			 @signed_date = @signed_date,
			 @signatory_email = @signatory_email,
			 @signatory_name = @signatory_name,
			 @signatory_contact_id = @signatory_contact_id,
			 @signatory_personal_tax_num = @signatory_personal_tax_num,
			 @bank_contract_id = @bank_contract_id output,
			 @error = @bank_error output
		end
	if @bank_contract_id is null
		begin
			set @DataErrorFlag = 1
			select @Error += '-@bank_contract_id is null but required' + isnull(@bank_error,'')
		end

	--********************This should moved into ord_ValidateOrdAccount once tax rates are automatically gotten from website but right now they are done manually so needs to be delayed*****************
	if @tax_district_required_flag = 1 and @tax_district is null and @green_upgrade_flag = 0
		begin
			set @DataErrorFlag = 1
			select @Error += '-@tax_district is null but required'
		end

	if @account_id is null and @OrdAccount_account_id is null and @DataErrorFlag = 0 and @green_upgrade_flag = 0
	
	--@OrdAccount_account_id and green_upgrade_flag shouldn't be needed since they shouldn't be null account_id also but is safety check
		begin
			set @Process = 'INSERT INTO cds.dbo.account'
			begin try

				insert into account
					(
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
					cancel_date,
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
					crg_AccntRecNum,
					crg_AccntSeqNum,
					crg_AcceptanceErr,
					inserted_date,
					inserted_by,
					updated_date,
					updated_by,
					signup_date,
					green_rate_id,
					margin_type_id,
					por_flag,
					contract_id,
					cancel_fee_flag,
					street_part,
					street_part_id,
					street_num,
					country_id,
					personal_tax_num,
					business_tax_num,
					gas_use_type_id,
					meter_num,
					utility_sub_id
					)
				select
					@utility_id,
					@commodity_id,
					@esco_id,
					@cust_id,
					case when @ord_account_hold_type_id is null then @account_status_id else @account_status_id_HOLD end,
					@facility_id,
					@csr_id,
					@cancel_reason_id,
					@language_id,
					@account_date,
					@welcome_letter_date,
					@accept_date,
					@cancel_date,
					@verif_date,
					@verif_num,
					@annual_usage,
					@account_num,
					@account_name,
					@address,
					@city,
					@state_id,
					@zip,
					@bill_account_name,
					@bill_address,
					@bill_city,
					@bill_state_id,
					@bill_zip,
					@zone,
					@load_profile,
					@strata,
					@pool_code,
					@rate_class,
					@tax_district,
					@program_code,
					@tax_exempt_flag,
					@budget_billing_flag,
					@tax_rate,
					@cancel_fee,
					@crg_AccntRecNum,
					@crg_AccntSeqNum,
					@crg_AcceptanceErr,
					@inserted_date,
					@inserted_by,
					@updated_date,
					@updated_by,
					@signup_date,
					@green_rate_id,
					@margin_type_id,
					@por_flag,
					@contract_id,
					@cancel_fee_flag,
					@street_part,
					@street_part_id,
					@street_num,
					@country_id,
					@personal_tax_num,
					@business_tax_num,
					@gas_use_type_id,
					@meter_num,
					@utility_sub_id
			end try

			begin catch
				EXECUTE dba_InsertProcError @ProcName, @Process
			end catch

			set @UpdateOrdAccountFlag = 1
			select @account_id = SCOPE_IDENTITY()
			
			select @esco_account_num = cast(@account_id as varchar(50)) + '00000'
			select @crg_AccntRecNum = @esco_account_num

			set @Process = 'INSERT cds.dbo.cust_account'
			begin try
				insert into cust_account (cust_id, account_id, [start_date], account_name)
				select @cust_id, @account_id, @account_date, @account_name
			end try
			begin catch
				EXECUTE dba_InsertProcError @ProcName, @Process
			end catch

			set @Process = 'UPDATE cds.dbo.account @esco_account_num'
			begin try
				update account set esco_account_num = @esco_account_num, crg_AccntRecNum = @crg_AccntRecNum where account_id = @account_id
			end try

			begin catch
				EXECUTE dba_InsertProcError @ProcName, @Process
			end catch

			set @Process = 'INSERT cds.dbo.account_bank_contract @account_id, @bank_contract_id'
			begin try
				exec cds_InsertAccountBankContract @account_id = @account_id, @bank_contract_id = @bank_contract_id, @error = @Error output
			end try

			begin catch
				EXECUTE dba_InsertProcError @ProcName, @Process
			end catch

			if @contract_id is not null
				begin
					set @Process = 'INSERT new cds.dbo.account_contract'
					begin try
						insert into account_contract (contract_id, account_id, [start_date])
						select @contract_id, @account_id, @contract_start_date
					end try

					begin catch
						EXECUTE dba_InsertProcError @ProcName, @Process
					end catch
				end

		end	
	else
		begin
			if @DataErrorFlag = 0
				begin
					--If not one of these status are handled below then put in review
					if (@account_status is null or
						 @account_status not in('ENROLL_REJECTED', 'ACTIVE', 'ENROLL_SENT', 'CANCELLED', 'CANCELLED_NO_INVOICE', 'CANCEL_REJECTED', 'CANCELLED_ENROLL_REJECTED_NOT_FIRST_IN', 'SENT_ESCO', 'RESENT_ESCO'))
						begin
							set @ord_account_status_id = @ord_account_status_id_REVIEW_NEW
							set @DataErrorFlag = 1
							select @Error += '-Account in wrong status ' + isnull(@account_status, '')
						end

					--If brown portion of same call green upgrade has not passed verif and post close then leave green upgrade in SEND_ESCO
					if @same_call_green_upgrade_flag = 1
						begin
							select @ord_account_status_id = os.ord_account_status_id, @DataErrorFlag = 1, @Error += '-Brown portion of same call green upgrade has not passed verif and post close'
							from ord_account oa
							--join ord_account oa2 on oa.mysql_order_account_id = oa2.mysql_order_account_id and oa.account_num = oa2.account_num and oa.utility_id = oa2.utility_id and oa.commodity_id = oa2.commodity_id and oa.esco_id = oa2.esco_id
							join ord_account oa2 on oa.import_order_account_id = oa2.import_order_account_id and oa.ord_source_id = oa2.ord_source_id and oa.account_num = oa2.account_num and oa.utility_id = oa2.utility_id and oa.commodity_id = oa2.commodity_id and oa.esco_id = oa2.esco_id
							join ord_account_status os on oa2.ord_account_status_id = os.ord_account_status_id
							join ord_verif_status vs on oa2.ord_verif_status_id = vs.ord_verif_status_id
							join ord_post_close_status pcs on oa2.ord_post_close_status_id = pcs.ord_post_close_status_id
							where oa.ord_account_id = @ord_account_id
							and oa.ord_account_id <> oa2.ord_account_id
							and oa.same_call_green_upgrade_flag = 1
							and oa2.same_call_green_upgrade_flag = 0
							and os.code = 'SEND_ESCO'
							and (vs.code <> 'GOOD' 
								or pcs.code <> 'GOOD')
						end

					--update account because of fixits done and resend them
					if @account_status = 'ENROLL_REJECTED'
						begin
							set @Process = 'Update CDS from CDS_Order Fixit'
							begin try	
								update a set 
										--NOTE: ord_account data is now being updated by SP cds_UpdateOrdFromESCO
										--a.account_num = @account_num,
										--a.utility_id = @utility_id,
										--a.commodity_id = @commodity_id,
										--a.facility_id = @facility_id,
										--a.account_name = @account_name,
										--a.pool_code = @pool_code,
										--a.[zone] = @zone,
										--a.strata = @strata,
										--a.load_profile = @load_profile,
										--a.program_code = @program_code,
										--a.tax_district = @tax_district,
										--a.tax_exempt_flag = @tax_exempt_flag,
										--a.tax_rate = @tax_rate,
										--a.[address] = @address,
										--a.state_id = @state_id,
										--a.zip = @zip,
										--a.budget_billing_flag = @budget_billing_flag,
										--a.green_rate_id = @green_rate_id,
										--a.por_flag = @por_flag,
										
										a.verif_date = @verif_date,
										a.verif_num = @verif_num,
										a.signup_date = @signup_date,
										a.csr_id = @csr_id,

										a.account_status_id = 5,--RESENT_ESCO
										a.updated_date = getdate(),
										a.updated_by = 'CDS_Order',									 
										@UpdateOrdAccountFlag = 1--set within here so it only is done if record is updated											
											
								from account a
								where a.account_id = @account_id
								and @account_id = isnull(@OrdAccount_account_id,@account_id)
								and @green_upgrade_flag = 0--not really needed since account_id should be NULL for these

								if @UpdateOrdAccountFlag = 1
									begin
										insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)
										select @account_id, @emp_id, @account_note_type_id_DATA_PROCESSING, getdate() , 'Update CDS from CDS_Order Fixit -- Enroll Again'
									end
								else
									begin
										set @ord_account_status_id = @ord_account_status_id_REVIEW_NEW
										set @DataErrorFlag = 1
										select @Error +=  '-Account in status ENROLL_REJECTED cannot be updated'
									end

							end try

							begin catch
								EXECUTE dba_InsertProcError @ProcName, @Process
							end catch
						end

					--green upgrade
					if @account_status in('ACTIVE', 'ENROLL_SENT', 'SENT_ESCO', 'RESENT_ESCO')
						begin
							if @green_upgrade_flag= 1 
								begin
									set @Process = 'Update CDS from CDS_Order Green Upgrade'
									begin try	
										update a set 
												green_rate_id = @green_rate_id
												,updated_date = getdate()
												,updated_by = 'CDS_Order'
												,verif_date = @verif_date
												,need_rate_change_flag = 1
												,@UpdateOrdAccountFlag = 1--set within here so it only is done if record is updated
												--,contract_id = @contract_id ** This may be needed here at some point								 										
										from account a
										where a.account_id = @account_id
										and a.green_rate_id is null
						
										if @UpdateOrdAccountFlag = 1
											begin
												insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)
												select @account_id, @emp_id, @account_note_type_id_DATA_PROCESSING, getdate() , 'Update CDS from CDS_Order Green Upgrade'
											end
										else
											begin
												set @ord_account_status_id = @ord_account_status_id_REVIEW_NEW
												set @ord_account_error_desc_id = @ord_account_error_desc_id_ALREADY_GREEN
												set @DataErrorFlag = 1
												select @Error += '-Account is already green'
											end

									end try

									begin catch
										EXECUTE dba_InsertProcError @ProcName, @Process
									end catch
								end
							else
								--This is to allow reinstatements through that have already been sent by utility from 3way call
								if @account_status = 'ACTIVE' and @retention_flag = 1
									begin
										set @Process = 'CDS account_status=ACTIVE but ret so do not change account status'
										begin try	
											update a set 
														verif_date = @verif_date
														,green_rate_id = @green_rate_id
														,updated_date = getdate()
														,updated_by = 'CDS_Order'
														,signup_date = @signup_date
											from account a
											where a.account_id = @account_id

											insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)
											select @account_id, @emp_id, @account_note_type_id_CRG_ACCOUNT_REMARK, getdate() , 'Reinstatement requested by CDS Order, Account status was already set to ACTIVE.'

											set @UpdateOrdAccountFlag = 1

										end try

										begin catch
											EXECUTE dba_InsertProcError @ProcName, @Process
										end catch										
									end

								else
									begin
										set @ord_account_status_id = @ord_account_status_id_DUPLICATE_NEW
										set @ord_account_error_desc_id = @ord_account_error_desc_id_DUPLICATE
										set @DataErrorFlag = 1
										select @Error += '-Account in wrong status to sell ' + isnull(@account_status, '')
									end
						end

					if (@account_status in('CANCELLED', 'CANCELLED_NO_INVOICE', 'CANCEL_REJECTED', 'CANCELLED_ENROLL_REJECTED_NOT_FIRST_IN')) and @green_upgrade_flag = 0
						begin
							if @signup_date > @cancel_date or @cancel_date is null
								begin

									--if CDS account is cancelled and CRG active with WinBack value reset CDS account status accordingly
									if @retention_flag = 1
										begin
											set @Process = 'CDS account_status=CANCELLED but winback or ret set status to REINSTATEMENT_PENDING'
											begin try	
												update a set account_status_id = 27--REINSTATEMENT_PENDING
															,verif_date = @verif_date
															,green_rate_id = @green_rate_id
															,updated_date = getdate()
															,updated_by = 'CDS_Order'
															,signup_date = @signup_date
															,contract_id = @contract_id
												from account a
												where a.account_id = @account_id

												update account_contract set end_date = case when dateadd(day,-1,@contract_start_date) < [start_date] then [start_date] else dateadd(day,-1,@contract_start_date) end
												where contract_id <> isnull(@contract_id,0)
												and account_id = @account_id 
												and end_date is null

												if @contract_id is not null
													begin
														if not exists (select 1 from account_contract where contract_id = @contract_id and account_id = @account_id)
															begin
																insert into account_contract (contract_id, account_id, [start_date])
																select @contract_id, @account_id, @contract_start_date
															end

														update account_contract set end_date = null
														where contract_id = @contract_id
														and account_id = @account_id
														and end_date is not null
													end

												insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)
												select @account_id, @emp_id, @account_note_type_id_CRG_ACCOUNT_REMARK, getdate() , 'Reinstatement requested by CDS Order, Account status set to REINSTATEMENT_PENDING.'

												set @UpdateOrdAccountFlag = 1

											end try

											begin catch
												EXECUTE dba_InsertProcError @ProcName, @Process
											end catch
										end

									--Handle winback and RET the same for PA but for NY RET is handled different as above
									if @winback_flag = 1
										begin
											set @Process = 'CDS account_status=CANCELLED and but winback or ret in CRG set status to REINSTATEMENT_ESCO'
											begin try	
												--we feel REINSTATEMENT_ESCO could be replaced with SENT_ESCO at a later time**************
												update a set account_status_id = case when @ord_account_hold_type_id is null then 26 /*REINSTATEMENT_ESCO*/ else @account_status_id_HOLD end
															,verif_date = @verif_date
															,green_rate_id = @green_rate_id
															,updated_date = getdate()
															,updated_by = 'CDS_Order'
															,signup_date = @signup_date
															,contract_id = @contract_id
															,cancel_fee = @cancel_fee
															,cancel_fee_flag = @cancel_fee_flag
															,axpo_esco_gas_id = null
															,csr_id = @csr_id
												from account a
												where a.account_id = @account_id

												update account_contract set end_date = case when dateadd(day,-1,@contract_start_date) < [start_date] then [start_date] else dateadd(day,-1,@contract_start_date) end
												where contract_id <> isnull(@contract_id,0)
												and account_id = @account_id 
												and end_date is null

												if @contract_id is not null
													begin
														if not exists (select 1 from account_contract where contract_id = @contract_id and account_id = @account_id)
															begin
																insert into account_contract (contract_id, account_id, [start_date])
																select @contract_id, @account_id, @contract_start_date
															end

														update account_contract set end_date = null
														where contract_id = @contract_id
														and account_id = @account_id
														and end_date is not null
													end

												insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)
												select @account_id, @emp_id, @account_note_type_id_CRG_ACCOUNT_REMARK, getdate() , 'Winback requested by CDS Order, Account status set to REINSTATEMENT_ESCO.'

												set @UpdateOrdAccountFlag = 1

											end try

											begin catch
												EXECUTE dba_InsertProcError @ProcName, @Process
											end catch
										end

									--CDS account_status=CANCELLED and Resold
									if (@retention_flag = 0 and @winback_flag = 0)
										begin
											set @Process = 'CDS account_status=CANCELLED and Resold'
											begin try	
												update a set account_status_id = case when @ord_account_hold_type_id is null then @account_status_id_SENT_ESCO else @account_status_id_HOLD end
															,verif_date = @verif_date
															,green_rate_id = @green_rate_id
															,updated_date = getdate()
															,updated_by = 'CDS_Order'
															,signup_date = @signup_date
															,contract_id = @contract_id
															,cancel_fee = @cancel_fee
															,cancel_fee_flag = @cancel_fee_flag
															,axpo_esco_gas_id = null
															,csr_id = @csr_id
												from account a
												where a.account_id = @account_id


												exec cds_InsertAccountBankContract @account_id = @account_id, @bank_contract_id = @bank_contract_id, @error = @Error output

												update account_contract set end_date = case when dateadd(day,-1,@contract_start_date) < [start_date] then [start_date] else dateadd(day,-1,@contract_start_date) end
												where contract_id <> isnull(@contract_id,0)
												and account_id = @account_id 
												and end_date is null

												if @contract_id is not null
													begin -- TODO ADD A CALL to  dbo.cds_InsertAccountBankContract
														if not exists (select 1 from account_contract where contract_id = @contract_id and account_id = @account_id)
															begin
																insert into account_contract (contract_id, account_id, [start_date])
																select @contract_id, @account_id, @contract_start_date
															end

														update account_contract set end_date = null
														where contract_id = @contract_id
														and account_id = @account_id
														and end_date is not null


													end

												insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)
												select @account_id, @emp_id, @account_note_type_id_CRG_ACCOUNT_REMARK, getdate() , 'CDS account_status=CANCELLED and Resold.'

												set @UpdateOrdAccountFlag = 1

											end try

											begin catch
												EXECUTE dba_InsertProcError @ProcName, @Process
											end catch
										end
								end
							else
								begin
									set @ord_account_status_id = @ord_account_status_id_REVIEW_NEW
									set @DataErrorFlag = 1
									select @Error += '-Signup date is earlier than cancel date'
								end
						end
	
				end
		end

		if @UpdateOrdAccountFlag = 1 and @DataErrorFlag = 0
			begin
				--update account_id and account_status for green_upgrades
				update oa set account_id = a.account_id, account_status = s.code
				from #account oa
				join account a on a.account_num = oa.account_num and a.utility_id = oa.utility_id and a.commodity_id = oa.commodity_id and a.esco_id = oa.esco_id
				join account_status s on s.account_status_id = a.account_status_id
				where oa.account_num = @account_num
				and oa.utility_id = @utility_id
				and oa.commodity_id = @commodity_id
				and oa.esco_id = @esco_id
				and oa.green_upgrade_flag = 1
				and oa.id > @i

				set @Process = 'UPDATE cds.dbo.ord_account'
				begin try
					update ord_account set account_id = @account_id, cds_process_date = getdate(), ord_account_status_id = @ord_account_status_id_SENT_ESCO
					where ord_account_id = @ord_account_id

					exec ord_UpdateOrdAccountPayStatus @ord_account_id = @ord_account_id
				end try

				begin catch
					EXECUTE dba_InsertProcError @ProcName, @Process
				end catch	

				--insert into account_note table
				set @Process = 'INSERT INTO cds.dbo.account_note'
				begin try

					insert into account_note (account_id, emp_id, account_note_type_id, note_date, note)					
					select @account_id, @emp_id, ord_account_note_type_id, note_date, note
					from ord_account_note oan
					where oan.ord_account_id = @ord_account_id 
					and oan.cds_process_date is null
					and not exists (select 1 from account_note an where an.account_id = @account_id 
									and (an.note = oan.note or an.note is null and oan.note is null)
									and (an.note_date = oan.note_date or an.note_date is null and oan.note_date is null)																				
									)					

				end try

				begin catch
					EXECUTE dba_InsertProcError @ProcName, @Process
				end catch


				set @Process = 'UPDATE cds.dbo.ord_account_note'
				begin try
					update oan set cds_process_date = getdate()
					from ord_account_note oan
					where oan.ord_account_id = @ord_account_id 
					and oan.cds_process_date is null
				end try

				begin catch
					EXECUTE dba_InsertProcError @ProcName, @Process
				end catch
			end		

		if @DataErrorFlag = 1 or @UpdateOrdAccountFlag = 0
			begin
				insert into ord_account_error (error_date, ord_account_id, error, ord_account_error_type_id, ord_account_error_desc_id)
				select getdate(), @ord_account_id , @Error, @ord_account_error_type_id_SEND_ESCO, @ord_account_error_desc_id
				where @Error <> ''

				set @Process = 'UPDATE cds.dbo.ord_account-REVIEW_NEW'
				begin try
					update ord_account set ord_account_status_id = isnull(@ord_account_status_id, @ord_account_status_id_REVIEW_NEW)--Paystatus not changed since Review New is Payable
					where ord_account_id = @ord_account_id
				end try

				begin catch
					EXECUTE dba_InsertProcError @ProcName, @Process
				end catch	
			end
		set @i += 1
	end

--HACK: This is to set accounts to green until the contract/product model is fully deployed***********************
update a set green_rate_id = ugr.green_rate_id
from account a
join account_contract ac on a.account_id = ac.account_id
join contract_item ci on ac.contract_id = ci.contract_id
join utility_green_rate ugr on a.esco_id = ugr.esco_id and a.utility_id = ugr.utility_id and a.commodity_id = ugr.commodity_id
where a.green_rate_id is null
and ac.[start_date] < getdate()
and (ac.end_date > getdate()
	or ac.end_date is null)
and ci.green_flag = 1

update cds_control set ord_account_status_SP_run_date = null
go

