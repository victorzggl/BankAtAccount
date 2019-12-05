use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_UpdateAccountAndBankFromContract]
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
document_key varchar(100) null,
bank_account varchar(100) not null,
account_num varchar(50) not null,
facility_id int not null,
personal_tax_num varchar(100) null,
business_tax_num varchar(100) null,
bank_change_flag bit not null,
account_change_flag bit not null,
bank_account_name varchar(100) not null,
bank_contract_id int null,
signatory_email varchar(255) null,
signatory_name varchar(101) null,
signatory_personal_tax_num varchar(100) null,
signatory_contact_id int null,
signed_date date null

)

insert into #update (ord_account_id, contract_id, account_id, ord_account_status, account_status, cust_id, bank_type_id, document_key, bank_account, account_num, facility_id, personal_tax_num, business_tax_num, bank_change_flag, account_change_flag, bank_account_name, signatory_email, signatory_name,	signatory_personal_tax_num,	signatory_contact_id, signed_date)
select oa.ord_account_id, c.contract_id, oa.account_id, oas.code [ord_account_status], s.code [account_status], a.cust_id, oa.bank_type_id, c.document_key, c.bank_account, c.account_num, c.facility_id, c.personal_tax_num, c.business_tax_num, c.bank_change_flag, c.account_change_flag, oa.bank_account_name, c.contract_email signatory_email , oct.first_name + ' ' + oct.last_name signatory_name , oct.personal_tax_num signatory_personal_tax_num, con.contact_id signatory_contact_id, c.signed_date
from ord_account oa
join ord_account_status oas on oa.ord_account_status_id = oas.ord_account_status_id
join [contract] c on oa.contract_id = c.contract_id
join contract_status cs on c.contract_status_id = cs.contract_status_id
join account a on oa.account_id = a.account_id
join account_status s on a.account_status_id = s.account_status_id
left join ord_contact oct on oct.ord_contact_id = c.signatory_ord_contact_id
left join (select top 1  cust_id, first_name, last_name, max(contact_id) contact_id from contact group by cust_id, first_name, last_name ) con on con.cust_id = oa.cust_id and con.first_name = oct.first_name and con.last_name = oct.last_name


where oa.bank_type_id is not null
and oas.resalable_flag = 0
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

declare @bank_id int, @cust_id int, @bank_type_id int, @bank_account varchar(100), @document_key varchar(100),
		@bank_change_flag bit, @account_change_flag bit, @account_status varchar(50), @account_id int, @contract_id int, @end_date date, @bank_account_name varchar(100), @error varchar(1000) = '',
		@signatory_email varchar(255), @signatory_name varchar(101), @signatory_contact_id int, @signatory_personal_tax_num varchar(100), @signed_date date, @bank_contract_id int

declare @id int = 1

while exists (select * from #update where id = @id)
begin
	select @bank_id = null, @cust_id = cust_id, @bank_type_id = bank_type_id, @bank_account = bank_account,
			@document_key = document_key, @bank_change_flag = bank_change_flag, @account_change_flag = account_change_flag,
			@account_status = account_status, @account_id = account_id, @contract_id = contract_id, @end_date = null, @bank_account_name = bank_account_name,
			@signatory_email = signatory_email, @signatory_name = signatory_name, @signatory_contact_id = signatory_contact_id, @signatory_personal_tax_num = signatory_personal_tax_num, @error = ''

	from #update
	where id = @id

	if @signatory_personal_tax_num is null --******** HACK: Needed because UI does not yet capture this data.
		set @signatory_personal_tax_num = ('FAKE TAX NUM' )

	if @bank_change_flag = 1
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
			 @error = @error output
	end

	if @bank_contract_id is null
		set @error = concat(@error, '; bank_contract_id did not generate for {contract_id:', @contract_id, ', cust_id:', @cust_id, '}')

	if @error = ''
	begin
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

	end

	set @id += 1
end

drop table #update
go

