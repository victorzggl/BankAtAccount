use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_UI_OrdAccountInsertNewContract] @ord_account_id int, @precheck_flag bit = 0, @account_num varchar(50) = null, @personal_tax_num varchar(100) = null, @business_tax_num varchar(100) = null, @ord_contact_id int = null
as

--exec cds_UI_OrdAccountInsertNewContract @ord_account_id = 356, @precheck_flag = 1

declare @error varchar(100), @contract_id int, @account_status varchar(50),
		@ord_account_status varchar(50), @resalable_flag bit,
		@bank_change_flag bit = 0, @account_change_flag bit = 0,
		@ReleaseVersion varchar(100) = 'Beta',
		@product_id int,
		@start_date date,
		@email varchar(255),
		@bank_account varchar(100),
		@facility_id int,
		@commodity_id int,
		@Process varchar(250)

select	@ord_account_status = s.code,
		@resalable_flag = s.resalable_flag
from ord_account oa
join ord_account_status s on oa.ord_account_status_id = s.ord_account_status_id
where oa.ord_account_id = @ord_account_id


--TODO: have UI pass account_num, personal_tax_num, and business_tax_num then return these error message if needed *************************
--account number already exists
--cannot change account number and tax numbers together associate needs to insert a new order

if @ord_account_status is null
	set @error = 'ord_account_id does not exist'

if @error is null and @resalable_flag = 1
	set @error = 'ord_account in wrong status - ' + @ord_account_status

if @error is null
	select @account_status = s.code
	from ord_account oa
	join account a on oa.account_id = a.account_id
	join account_status s on a.account_status_id = s.account_status_id
	where oa.ord_account_id = @ord_account_id

if @error is null and @account_status not in ('SENT_ESCO','RESENT_ESCO','ENROLL_REJECTED','ACTIVE')
	set @error = 'account in wrong status - ' + @account_status

if @error is null and @ReleaseVersion = 'Beta' and not exists(select 1 from ord_contact oc join ord_contact_type oct on oct.ord_contact_type_id = oc.ord_contact_type_id join ord_account oa on oa.ord_cust_id = oc.ord_cust_id where oa.ord_account_id = @ord_account_id and oct.code in ('DM','CONTRACT_SIGNATORY'))
	set @ord_contact_id = (select max(ord_contact_id) ord_contact_id from ord_contact oc join ord_contact_type oct on oct.ord_contact_type_id = oc.ord_contact_type_id join ord_account oa on oa.ord_cust_id = oc.ord_cust_id where oa.ord_account_id = @ord_account_id and oct.code in ('DM','CONTRACT_SIGNATORY'))
else if @error is null and not exists(select 1 from ord_contact oc join ord_contact_type oct on oct.ord_contact_type_id = oc.ord_contact_type_id where oc.ord_contact_id = @ord_contact_id and oct.code in ('DM','CONTRACT_SIGNATORY'))
	set @error  = 'must be a valid ord_contact_type DM OR CONTRACT_SIGNATORY'




if @error is null and @account_status = 'ACTIVE' and @account_change_flag = 1
	set @error = 'only bank changes are allowed when account is active'

if @error is null and @precheck_flag = 0
begin
	execute cds_UpdateOrdFromESCO @ord_account_id = @ord_account_id

	declare @contract_status_INACTIVE int = (select contract_status_id from contract_status where code = 'INACTIVE')
	
	update c set contract_status_id = @contract_status_INACTIVE
	from ord_account oa
	join [contract] c on oa.contract_id = c.contract_id
	where oa.ord_account_id = @ord_account_id


	select
		@product_id = c.product_id,
		@start_date = getdate(),
		@email = isnull(oc.email1, oc.email2) [contract_email],
		@bank_account = oa.bank_account,
		@account_num = oa.account_num,
		@facility_id = oa.facility_id,
		@commodity_id = oa.commodity_id,
		@personal_tax_num = upper(oa.personal_tax_num),
		@business_tax_num = upper(oa.business_tax_num)
	from ord_account oa
	join [contract] c on oa.contract_id = c.contract_id
	join ord_contact oc on oa.ord_cust_id = oc.ord_cust_id
	join ord_contact_type oct on oc.ord_contact_type_id = oct.ord_contact_type_id
	where oa.ord_account_id = @ord_account_id
	and oct.code in ('DM', 'CONTRACT_SIGNATORY')

	begin try
		execute cds_InsertContract @product_id = @product_id, @start_date = @start_date, @email = @email, @bank_account = @bank_account, @account_num = @account_num, @facility_id = @facility_id, @commodity_id = @commodity_id, @personal_tax_num = @personal_tax_num, @business_tax_num = @business_tax_num,@Process = @Process ,@contract_id = @contract_id output, @Error = @Error output, @signatory_ord_contact_id = @ord_contact_id
	end try
	begin catch
		set @error = isnull(@error, error_message())
		exec dba_InsertProcError @ProcName = ProcName, @InternalError = @error
	end catch

	if @error is null and @contract_id is not null
	begin
		update oa set contract_id = @contract_id
		from ord_account oa
		where oa.ord_account_id = @ord_account_id

		update ac set end_date = case when ac.[start_date] >= cast(getdate() as date) then ac.[start_date] else dateadd(day,-1,cast(getdate() as date)) end
		from ord_account oa
		join account_contract ac on oa.account_id = ac.account_id
		where oa.ord_account_id = @ord_account_id
		and ac.end_date is null
	end
end

select isnull(@error,@contract_id) [results]
go
