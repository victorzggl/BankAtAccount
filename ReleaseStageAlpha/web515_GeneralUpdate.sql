use WEB_515_IT
go

drop index dbo.Bank.UQ_BankIdCustid

alter table dbo.contract add SignatoryOrdContactId int null

alter table dbo.contact add PersonalTaxNum varchar(100) null

create unique index dbo.[UX_DocumentKey] on dbo.contract (DocumentKey) where (DocumentKey is not null)