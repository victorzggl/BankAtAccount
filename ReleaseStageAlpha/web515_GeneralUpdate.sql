use WEB_515_IT
go

drop index dbo.Bank.UQ_BankIdCustid

alter table dbo.contract add SignatoryOrdContactId int null

alter table dbo.contact add PersonalTaxNum varchar(100) null


insert into OrderContactType (code, name, description)
select 'CONTRACT_SIGNATORY', 'Contract Signatory', 'Contract Signatory if different from DM'
