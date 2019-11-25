use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[cds_ActivateBank] @bank_id int, @error varchar(500) = null output
as
set @error = ''

if not exists (select * from bank where bank_id = @bank_id)
	set @error += '; must be valid bank_id'
if not exists (select * from cds_fn_GetActiveBankContract (@bank_id, null, null ) ) and @error = ''
	set @error += '; must have active bank contract'

declare @bank_status_ACTIVE int = (select bank_status_id from bank_status where code = 'ACTIVE')

update bank set bank_status_id = @bank_status_ACTIVE, bank_status_date = getdate()
where bank_id = @bank_id
and bank_status_id <> @bank_status_ACTIVE

go

