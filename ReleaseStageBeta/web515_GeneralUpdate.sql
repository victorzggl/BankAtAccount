use WEB_515_IT
go

create unique index dbo.[UX_DocumentKey] on dbo.contract (DocumentKey) where (DocumentKey is not null)
