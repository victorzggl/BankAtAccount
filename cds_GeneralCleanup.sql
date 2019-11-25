use CDS
go

-- TODO POPULATE TABLES WITH EXISTING DATA


-- drop table #bank_contract
create table #bank_contract (
	bank_contract_id           int                                                          not null identity constraint xPK_bank_contract primary key,
	bank_contract_status_id    int                                                          not null constraint xFK_bank_contract_bank_contract_status references bank_contract_status,
	cust_id                    int                                                          not null constraint [xFK_bank_contract_cust] references cust,
	signed_date                date                                                         null,
	start_date                 date                                                         null,
	end_date                   date                                                         null,
	document_key               varchar(100)                                                 null,
	signatory_email            varchar(255)                                                 null,
	signatory_name             varchar(100)                                                 null,
	signatory_contact_id       int                                                          null,
	signatory_personal_tax_num varchar(100)                                                 null,
	bank_account_name          varchar(100)                                                 null,
	bank_account               varchar(100)                                                 null,
	contract_id                int                                                          null,
	bank_id                    int                                                          null constraint [xFK_bank_contract_bank] references bank,
	inserted_date              datetime                                                     not null constraint xDF_bank_contract_inserted_date default getdate(),
	updated_date               datetime                                                     null,
	constraint CK_bank_contract_start_date_end_date
		check ([start_date] <= [end_date] or [end_date] is null)
)







insert into #bank_contract (bank_contract_status_id, cust_id, signed_date, start_date, end_date, document_key, signatory_email, signatory_name, signatory_contact_id, signatory_personal_tax_num, bank_account_name, bank_account, contract_id, bank_id)
select case when bs.code = 'ACTIVE' then 3 /*ACTIVE*/ else 4 /*INACTIVE*/ end bank_contract_status_id, b.cust_id, c.signed_date, c.start_date, mx_contract.end_date, c.document_key, c.contract_email signatory_email, null signatory_name, null signatory_contact_id, null signatory_personal_tax_num, null bank_account_name, b.bank_account, c.contract_id, b.bank_id
from bank b
join bank_status bs on bs.bank_status_id = b.bank_status_id
join contract c on b.document_key = c.document_key
left join  (select max(end_date) end_date, ac.contract_id from account_contract ac where end_date is not null group by ac.contract_id ) mx_contract on mx_contract.contract_id = c.contract_id
-- where exists(select 1 from account_contract  ac where ac.contract_id = mx_contract.contract_id and ac.end_date is null )

/*create table #csr_signatory (csr_id int not null, cust_id int )
create unique index [UX_CsrIdCustIdTEMPTABLE] on #csr_signatory(csr_id, cust_id)
-- drop table #csr_signatory

insert into #csr_signatory (csr_id, cust_id)
select distinct c.csr_id, cust_id
from #bank_contract bc
join csr c on c.email = bc.signatory_email
where bc.signatory_contact_id is null
and not exists(select 1 from contact c2 where c2.cust_id = bc.cust_id and (bc.signatory_email = c2.email1 or bc.signatory_email = c2.email2))

-- insert into contact_type (contact_type_id, code, name, description, active_flag, sync_status_id)
-- values (8,'CSR', 'Csr Signed A Customer Contract', null, 1, 1);
--

-- alter table contact add csr_id int null constraint [FK_contact_csr] references csr
-- alter table contact drop constraint FK_contact_csr
-- alter table contact drop column csr_id

-- select *
-- from cds.dbo.contact c
-- where inserted_by = 'CSSLLC\VICTORZ'
-- insert into contact(cust_id, emp_id, contact_status_id, contact_type_id, first_name, last_name, phone1, phone1_ext, phone2, phone2_ext, cell_phone, email1, email2, title, inserted_date, inserted_by, csr_id)
select
	cs.cust_id cust_id
	,5 [emp_id]
	,1 [contact_status_id]
	,ct.contact_type_id
	,c.first_name
	,c.last_name
	,null phone1
	,null phone1_ext
	,null phone2
	,null phone2_ext
	,null cell_phone
	,c.email email1
	,null email2
	,null title--,isnull(oc.title,ct.name) [title]
	,getdate() [inserted_date]
	,'CSSLLC\VICTORZ' [inserted_by]
	,cs.csr_id
from #csr_signatory cs
join csr c on c.csr_id = cs.csr_id
cross join contact_type ct
where ct.code = 'CSR'
*/


begin
-- 	select *
	update bc set signatory_contact_id = c.contact_id, signatory_name = concat(ocu.first_name, ' ', ocu.last_name)
	from #bank_contract bc
	join CDS_515.dbo.order_contact_update ocu on isnull(ocu.email1,ocu.email2) = bc.signatory_email
	join CDS.dbo.ord_contact oc on oc.ord_contact_id = ocu.cds_ord_contact_id
	join cds.dbo.contact c on isnull(c.email1,c.email2) = isnull(oc.email1,oc.email2)
	where signatory_contact_id is null and ocu.cds_ord_contact_id is not null

-- 	select ct.code,*
	update bc set signatory_contact_id = c.contact_id, signatory_name = concat(c.first_name, ' ', c.last_name)
	from #bank_contract bc
	left join contact c on c.cust_id = bc.cust_id
	left join contact_type ct on ct.contact_type_id = c.contact_type_id
	where signatory_contact_id is null
	and ct.code = 'WL'
end

begin
-- 	select a.personal_tax_num,a.business_tax_num, *
	update bc set signatory_personal_tax_num = a.personal_tax_num
	from #bank_contract bc
	join contract c on c.contract_id = bc.contract_id
	join account_contract ac on ac.contract_id = c.contract_id
	join account a on a.account_id = ac.account_id and a.cust_id = bc.cust_id
	where (bc.signatory_personal_tax_num is null )

-- 	select bc.signatory_personal_tax_num, bc.signatory_business_tax_num, *
	update bc set signatory_personal_tax_num = c.personal_tax_num
	from #bank_contract bc
	join cust c on c.cust_id = bc.cust_id
	where (bc.signatory_personal_tax_num is null )
end




select *
from #bank_contract bc


select c.csr_id,cust_id,bc.signatory_email,c.csr_name
-- update bc set signatory_contact_id = c.contact_id, bc.signatory_name = concat(c.first_name, ' ', last_name), signatory_personal_tax_num = c2.personal_tax_num, signatory_business_tax_num = c2.business_tax_num
from #bank_contract bc
join csr c on c.email = bc.signatory_email
where bc.signatory_contact_id is null

select *
update bc set signatory_contact_id = c.contact_id, bc.signatory_name = concat(c.first_name, ' ', last_name), signatory_personal_tax_num = c2.personal_tax_num
from #bank_contract bc
join contact c on isnull(nullif(c.email1,''),nullif(c.email2,'')) = bc.signatory_email
join cust c2 on c2.cust_id = c.cust_id
where bc.signatory_contact_id is null
and c.cust_id = bc.cust_id

-- select c2.business_tax_num,c2.personal_tax_num,c.contact_id,bc.*
update bc set signatory_contact_id = c.contact_id, bc.signatory_name = concat(c.first_name, ' ', last_name), signatory_personal_tax_num = c2.personal_tax_num
from #bank_contract bc
join contact c on isnull(nullif(c.email1,''),nullif(c.email2,'')) = bc.signatory_email
join cust c2 on c2.cust_id = c.cust_id
where bc.signatory_contact_id is null


create table #ord_contact (	ord_contact_id int primary key)
-- drop table #ord_contact

insert into #ord_contact (ord_contact_id)
select distinct oc.ord_contact_id
from #bank_contract bc
join ord_contact oc on coalesce(oc.email1,oc.email2) = bc.signatory_email
join ord_cust o on o.ord_cust_id = oc.ord_cust_id
where bc.signatory_contact_id is null
and o.cust_id is not null

insert into #ord_contact (ord_contact_id)
select distinct oc.ord_contact_id
from #bank_contract bc
join ord_contact oc on coalesce(oc.email2,oc.email1) = bc.signatory_email
join ord_cust o on o.ord_cust_id = oc.ord_cust_id
where bc.signatory_contact_id is null
and o.cust_id is not null
and not exists(select 1 from #ord_contact o where o.ord_contact_id = oc.ord_contact_id)

select *
from #ord_contact oc


insert into contact(cust_id,emp_id,contact_status_id,contact_type_id,first_name,last_name,phone1,phone1_ext,phone2,phone2_ext,cell_phone,email1,email2,title,inserted_date,inserted_by)
select
	c.cust_id cust_id
	,5 [emp_id]
	,1 [contact_status_id]
	,oct.ord_contact_type_id
	,oc.first_name
	,oc.last_name
	,oc.phone1
	,oc.phone1_ext
	,oc.phone2
	,oc.phone2_ext
	,oc.cell_phone
	,oc.email1
	,oc.email2
	,oc.title--,isnull(oc.title,ct.name) [title]
	,getdate() [inserted_date]
	,'CSSLLC\VICTORZ' [inserted_by]
from #ord_contact o
join ord_contact oc on o.ord_contact_id = oc.ord_contact_id
join ord_cust c on c.ord_cust_id = oc.ord_cust_id
join contact_title ct on ct.contact_title_id = oc.contact_title_id
cross join ord_contact_type oct
where oct.code = 'OTHER'



select *
update bc set signatory_contact_id = c.contact_id, bc.signatory_name = concat(c.first_name, ' ', last_name), signatory_personal_tax_num = c2.personal_tax_num
from #bank_contract bc
join contact c on isnull(nullif(c.email1,''),nullif(c.email2,'')) = bc.signatory_email
join cust c2 on c2.cust_id = c.cust_id
where bc.signatory_contact_id is null
and c.cust_id = bc.cust_id

-- select c2.business_tax_num,c2.personal_tax_num,c.contact_id,bc.*
update bc set signatory_contact_id = c.contact_id, bc.signatory_name = concat(c.first_name, ' ', last_name), signatory_personal_tax_num = c2.personal_tax_num
from #bank_contract bc
join contact c on isnull(nullif(c.email1,''),nullif(c.email2,'')) = bc.signatory_email
join cust c2 on c2.cust_id = c.cust_id
where bc.signatory_contact_id is null


select *
from ord_contact oc
where oc.ord_contact_id = 12672

select bc.signatory_email,bc.cust_id,c.bank_account, bc.bank_account
from #bank_contract bc
join contract c on c.contract_email  = bc.signatory_email
join account_contract ac on ac.contract_id = c.contract_id
join account a on a.account_id = ac.account_id
join cust c2 on c2.cust_id = bc.cust_id and c2.cust_id = a.cust_id
where bc.signatory_contact_id is null
and c.bank_account = bc.bank_account
and (
	not exists(select 1 from contact c3 where c3.email1 = bc.signatory_email)
	and not exists(select 1 from contact c4 where c4.email2 = bc.signatory_email)
	)


select c.email, *
from #bank_contract bc
left join csr c on (c.email) = bc.signatory_email
where bc.signatory_contact_id is null


select *
from CDS_515.dbo.contact_update cu
where original_record_flag <> 1
select *
from CDS_515.dbo.order_contact_update ocu

select *
from CDS.dbo.contact c
select *
from bank_status bs