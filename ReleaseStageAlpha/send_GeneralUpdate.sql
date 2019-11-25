use CDS_Send
go

-- existing tables
alter table cust_send add bank_contract_id int null
alter table cust_send add bank_reg_key varchar(100) null


create index IX_BankContractId on cust_send(bank_contract_id) where bank_contract_id is not null

-- existing tables