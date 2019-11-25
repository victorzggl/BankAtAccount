
CREATE procedure [dbo].[cds_UpdateAccountAndBankFromContract]
as

create table #update
(id int not null identity(1,1) primary key,
ord_account_id int not null, 
contract_id int not null, 
account_id int not null,
ord_account_status varchar(50) not null, 
account_status varchar(50) not null, 
cust_id int not null, 
bank_type_id int not null, 
bank_reg_key varchar(100) not null, 
verif_date datetime not null, 
document_key varchar(100) null, 
bank_account varchar(100) not null, 
account_num varchar(50) not null, 
facility_id int not null, 
personal_tax_num varchar(100) null, 
business_tax_num varchar(100) null, 
bank_change_flag bit not null, 
account_change_flag bit not null,
bank_account_name varchar(100) not null)

insert into #update (ord_account_id, contract_id, account_id, ord_account_status, account_status, cust_id, bank_type_id, bank_reg_key, verif_date, document_key, bank_account, account_num, facility_id, personal_tax_num, business_tax_num, bank_change_flag, account_change_flag, bank_account_name)
select oa.ord_account_id, c.contract_id, oa.account_id, oas.code [ord_account_status], s.code [account_status], a.cust_id, oa.bank_type_id, oc.bank_reg_key, c.signed_date [verif_date], c.document_key, c.bank_account, c.account_num, c.facility_id, c.personal_tax_num, c.business_tax_num, c.bank_change_flag, c.account_change_flag, oa.bank_account_name
from ord_account oa
join ord_account_status oas on oa.ord_account_status_id = oas.ord_account_status_id
join ord_cust oc on oa.ord_cust_id = oc.ord_cust_id
join [contract] c on oa.contract_id = c.contract_id
join contract_status cs on c.contract_status_id = cs.contract_status_id
join account a on oa.account_id = a.account_id
join account_status s on a.account_status_id = s.account_status_id
where oa.bank_type_id is not null
and oas.resalable_flag = 0
and oc.bank_reg_key is not null
and oas.code not in ('SEND_CUST')
and not (s.code in ('ACTIVE','ENROLL_SENT') and c.account_change_flag = 1)
and c.signed_date is not null
and c.[start_date] is not null
and c.bank_account is not null
and c.account_num is not null
and c.facility_id is not null
and not (c.personal_tax_num is null and c.business_tax_num is null)
and cs.code in ('PENDING','ACTIVE')
and (not exists (select * from account_contract ac where oa.account_id = ac.account_id and oa.contract_id = ac.contract_id)
	or c.bank_change_flag = 1
	or c.account_change_flag = 1)

declare @bank_id int, @cust_id int, @bank_type_id int, @bank_reg_key varchar(100), @bank_account varchar(100), @verif_date datetime, @document_key varchar(100),
		@bank_change_flag bit, @account_change_flag bit, @account_status varchar(50), @account_id int, @contract_id int, @end_date date, @bank_account_name varchar(100), @error varchar(1000) = ''

declare @id int = 1

while exists (select * from #update where id = @id)
begin
	select @bank_id = null, @cust_id = cust_id, @bank_type_id = bank_type_id, @bank_reg_key = bank_reg_key, @bank_account = bank_account,
			@verif_date = verif_date, @document_key = document_key, @bank_change_flag = bank_change_flag, @account_change_flag = account_change_flag,
			@account_status = account_status, @account_id = account_id, @contract_id = contract_id, @end_date = null, @bank_account_name = bank_account_name
	from #update
	where id = @id

	if @bank_change_flag = 1
	begin
		if not exists(select 1 from bank b where cust_id = @cust_id and bank_account = @bank_account)
		begin
			exec cds_InsertBank @cust_id = @cust_id, @bank_type_id = @bank_type_id, @bank_reg_key = @bank_reg_key, @bank_account = @bank_account, @description = '', @signed_date = @verif_date, @document_key = @document_key, @bank_id = @bank_id output
			, @bank_account_name = @bank_account_name
		end
		else -- update
		begin
			exec cds_UpdateBank @cust_id = @cust_id, @bank_type_id = @bank_type_id, @bank_reg_key = @bank_reg_key, @bank_account = @bank_account, @description = '', @signed_date = @verif_date, @document_key = @document_key, @bank_id = @bank_id, @bank_account_name = @bank_account_name, @error = @error output
		end
	end

	if @account_change_flag = 1
	begin
		update a set account_num = u.account_num, facility_id = u.facility_id, personal_tax_num = u.personal_tax_num, business_tax_num = u.business_tax_num
		from account a
		join #update u on a.account_id = u.account_id
		where u.id = @id
	end

	if (@bank_change_flag = 1 or @account_change_flag = 1) and @error = ''
	begin
		update [contract] set bank_change_flag = 0, account_change_flag = 0 where contract_id = @contract_id
	end

	if not exists (select * from account_contract where account_id = @account_id and contract_id = @contract_id) and @error = ''
	begin
		update ac set end_date = case when ac.[start_date] >= cast(getdate() as date) then ac.[start_date] else dateadd(day,-1,cast(getdate() as date)) end
		from account_contract ac
		where ac.account_id = @account_id
		and ac.end_date is null

		select @end_date = max(end_date) from account_contract where account_id = @account_id

		insert into account_contract (contract_id, account_id, [start_date])
		select @contract_id, @account_id, dateadd(day,1,@end_date)
	end

	if @account_status = 'ENROLL_REJECTED' and @error = ''
	begin
		update a set account_status_id = s.account_status_id
		from account a
		cross join account_status s
		where a.account_id = @account_id
		and s.code = 'RESENT_ESCO'
	end

	set @id += 1
end

drop table #update
go

