use CDS
go


create table dbo.bank_contract_status (
bank_contract_status_id int identity constraint PK_bank_contract_status primary key,
code                    varchar(50) not null,
name                    varchar(50) not null,
description             varchar(100)
)
create unique index [UX_Code] on dbo.bank_contract_status (code)


insert into dbo.bank_contract_status (code, name, description)
values ('NEW', 'New', 'New')
	 , ('PENDING', 'Pending', 'new contracts for which .pdf documents need to be generated, then signed')
	 , ('ACTIVE', 'Active', 'even though signed, a contract may not yet be ACTIVE, which is an additional step')
	 , ('INACTIVE', 'Inactive', 'ACTIVE contracts can at some point be made INACTIVE')
	 , ('NEEDS_REVIEW', 'NEEDS_REVIEW', 'Signed contract could not be set to ACTIVE')

-- auto-generated definition
create table dbo.bank_contract (
	bank_contract_id           int                                                          not null identity constraint PK_bank_contract primary key,
	bank_contract_status_id    int                                                          not null constraint FK_bank_contract_bank_contract_status references bank_contract_status,
	cust_id                    int                                                          not null constraint [FK_bank_contract_cust] references dbo.cust,
	signed_date                date                                                         null,
	start_date                 date                                                         not null,
	end_date                   date                                                         null,
	document_key               varchar(100)                                                 null,
	signatory_email            varchar(255)                                                 not null,
	signatory_name             varchar(100)                                                 not null,
	signatory_contact_id       int                                                          not null constraint [FK_bank_contract_contact] references dbo.contact,
	signatory_personal_tax_num varchar(100)                                                 not null,
	bank_account_name          varchar(100)                                                 not null,
	bank_account               varchar(100)                                                 not null,
	contract_id                int                                                          null constraint [FK_bank_contract_contract] references dbo.contract,
	bank_id                    int                                                          null constraint [FK_bank_contract_bank] references dbo.bank,
	inserted_date              datetime                                                     not null constraint DF_bank_contract_inserted_date default getdate(),
	updated_date               datetime                                                     null,
	bank_type_id               int                                                          not null constraint [FK_bank_contract_bank_type] references dbo.bank_type,
	sync_status_id             int constraint DF_bank_contract_sync_status_id default ((1)) not null constraint FK_bank_contract_sync_status references dbo.sync_status,
	bank_authorization_key     varchar(100)                                                 null,
	bank_reg_key               varchar(100)                                                 null,
	error                      varchar(max)                                                 null,
	constraint CK_bank_contract_start_date_end_date check ([start_date] <= [end_date] or [end_date] is null),
	constraint [CK_bank_contract_signatory_personal_tax_num] check (signatory_personal_tax_num <> '' )
)



create index IX_SignedDate on bank_contract(signed_date) include (bank_contract_id)

create unique index UX_DocumentKeyContractIdBankId on bank_contract(document_key, contract_id, bank_id)  where (document_key is not null and bank_id is not null)



create table dbo.account_bank_contract (
	account_bank_contract_id int  not null constraint [PK_account_bank_contract] primary key identity,
	account_id               int  not null constraint [FK_account_bank_contract_account] references dbo.account,
	bank_contract_id         int  not null constraint [FK_account_bank_contract_bank_contract] references dbo.bank_contract,
	start_date               date not null,
	end_date                 date null,
	active_flag              bit  not null constraint [DF_account_bank_contract_active_flag] default 0,
	constraint CK_account_bank_contract_start_date_end_date check ([start_date] <= [end_date] or [end_date] is null),
	constraint [CK_account_bank_contract_end_date_active_flag] check ((end_date is not null and active_flag = 0 ) or end_date is null)
)
create index [IX_ActiveAccountId] on account_bank_contract(account_id) where active_flag = 1
create unique index [UX_AccountIdBankContractId] on account_bank_contract(account_id, bank_contract_id)


-- existing tables
	alter table dbo.contract add signatory_ord_contact_id int null

	alter table dbo.contact add personal_tax_num varchar(100) null

	alter table dbo.bank_transaction add bank_contract_id int null constraint [FK_bank_transaction_bank_contract] references bank_contract

	use CDS_515
	go

	alter table bank drop constraint [UQ_BankIDCustID]
-- 	drop index dbo.bank.UQ_BankIDCustID

	use CDS
	go

	insert into ord_contact_type (code, name, description)
	select 'CONTRACT_SIGNATORY', 'Contract Signatory', 'Contract Signatory if different from DM'

	insert into contact_type (contact_type_id, code, name, description)
	select 8,'CONTRACT_SIGNATORY', 'Contract Signatory', 'Contract Signatory if different from DM'


-- existing tables