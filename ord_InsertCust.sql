use CDS
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[ord_InsertCust] @ord_cust_id int = null
as 

declare	@ProcName varchar(100) = 'ord_InsertCust', 
		@Process varchar(1000), 
		@Error varchar(100),
		@emp_id_CDSOrdImport int = (select emp_id from emp where first_name = 'CDSOrdImport' and last_name = 'CDSOrdImport'),
		@contact_status_id_ACTIVE int = (select contact_status_id from contact_status where code = 'ACTIVE')

declare
	@id int,
	@cust_id int,
	@cust_date datetime,
	@cust_num varchar(50),
	@cust_name varchar(100),
	@address varchar(100),
	@city varchar(100),
	@state_id int,
	@zip varchar(100),
	@crg_CustRecNum varchar(50),
	@crg_CustSeqNum int,
	@inserted_date datetime,
	@inserted_by varchar(50),
	@updated_date datetime,
	@updated_by varchar(50),
	@OLD_crg_CustSeqNum int,
	@esco_id int,
	@street_num varchar(50),
	@street_part varchar(50),
	@country_id int,
	@state_code varchar(50),
	@language_id int,
	@birth_date date,
	@birth_country_id int,
	@bank_reg_key varchar(100),
	@personal_tax_num varchar(100),
	@business_tax_num varchar(100)

create table #cust(
	id int IDENTITY(1,1) NOT NULL Primary key,
	ord_cust_id int NOT NULL,
	cust_id int NULL,
	cust_date datetime NULL,
	cust_num varchar(50) NULL,
	cust_name varchar(100) NULL,
	[address] varchar(100) NULL,
	city varchar(100) NULL,
	state_id int NULL,
	zip varchar(100) NULL,
	crg_CustRecNum varchar(50) NULL,
	crg_CustSeqNum int NULL,
	inserted_date datetime NOT NULL,
	inserted_by varchar(50) NULL,
	updated_date datetime NOT NULL,
	updated_by varchar(50) NULL,
	OLD_crg_CustSeqNum int NULL,
	esco_id int NOT NULL,
	street_num varchar(50) NULL,
	street_part varchar(50) NULL,
	country_id int NOT NULL,
	state_code varchar(50) NULL,
	language_id int NULL,
	birth_date date NULL,
	birth_country_id int NULL,
	bank_reg_key varchar(100) NULL,
	personal_tax_num varchar(100) null,
	business_tax_num varchar(100) null
	)

insert into #cust
           (ord_cust_id
		   ,cust_id
		   ,cust_date
           ,cust_num
		   ,cust_name
           ,[address]
           ,city
           ,state_id
           ,zip
           ,crg_CustRecNum
           ,crg_CustSeqNum
           ,inserted_date
           ,inserted_by
           ,updated_date
           ,updated_by
		   ,OLD_crg_CustSeqNum
		   ,esco_id
		   ,street_num
		   ,street_part
		   ,country_id
		   ,state_code
		   ,language_id
		   ,birth_date
		   ,birth_country_id
		   ,bank_reg_key
		   ,personal_tax_num
		   ,business_tax_num
)
select
	oc.ord_cust_id		
	,c.cust_id
	,getdate() [cust_date]
	,oc.cust_num
	,oc.cust_name
	,oc.[address]
	,oc.city
	,oc.state_id
	,oc.zip
	,oc.crg_CustRecNum 
	,oc.crg_CustSeqNum
	,getdate() [inserted_date]
	,'CDS_Order' [inserted_by]
	,getdate() [updated_date]
	,'CDS_Order' [updated_by]
	,c.crg_CustSeqNum
	,oc.esco_id
	,oc.street_num
	,oc.street_part
	,oc.country_id
	,oc.state_code
	,oc.language_id
	,oc.birth_date
	,oc.birth_country_id
	,oc.bank_reg_key
    ,upper(isnull(c.personal_tax_num,oc.personal_tax_num))
    ,upper(isnull(c.business_tax_num,oc.business_tax_num))
from ord_cust oc
left join cust c on c.cust_num = oc.cust_num
where oc.cust_id is null
and (oc.ord_cust_id = @ord_cust_id or @ord_cust_id is null)
and oc.cust_num is not null
and oc.bank_reg_key is not null
and nullif(oc.bank_account,'') is not null
--Make sure the ord_cust has an account that is either ready to send to CDS or has already been sent
and exists(select 1 from ord_account oa
					join ord_account_status s on s.ord_account_status_id = oa.ord_account_status_id
					--join ord_verif_status vs on vs.ord_verif_status_id = oa.ord_verif_status_id
					--join ord_post_close_status ps on ps.ord_post_close_status_id = oa.ord_post_close_status_id 
					join [contract] c on c.contract_id = oa.contract_id
					join csr on oa.csr_id = csr.csr_id
					where oa.ord_cust_id = oc.ord_cust_id 
					and (oa.account_id is not null 
					or (s.code = 'SEND_ESCO'
						--and vs.code = 'GOOD'
						--and ps.code = 'GOOD'
						and oa.bank_type_id is not null
						and c.signed_date is not null
						and csr.test_csr_flag = 0)))

declare @i int, @total int

set @i = 1
select @total = count(*) from #cust

while @i <= @total
	begin
		select 
			@id = id,
			@ord_cust_id = ord_cust_id,
			@cust_id = cust_id,
			@cust_date = cust_date,
			@cust_num = cust_num,
			@cust_name = cust_name,
			@address = [address],
			@city = city,
			@state_id = state_id,
			@zip = zip,
			@crg_CustRecNum = crg_CustRecNum,
			@crg_CustSeqNum = crg_CustSeqNum,
			@inserted_date = inserted_date,
			@inserted_by = inserted_by,
			@updated_date = updated_date,
			@updated_by = updated_by,
			@OLD_crg_CustSeqNum = OLD_crg_CustSeqNum,
			@esco_id = esco_id,
			@street_num = street_num,
			@street_part = street_part,
			@country_id = country_id,
			@state_code = state_code,
			@language_id = language_id,
			@birth_date = birth_date,
			@birth_country_id = birth_country_id,
			@bank_reg_key = bank_reg_key,
		    @personal_tax_num = personal_tax_num,
		    @business_tax_num = business_tax_num
		from #cust
		where id = @i

	if @cust_id is null
		begin
			set @Process = 'INSERT INTO cds.dbo.cust'
			begin try
				insert into cust
					(
				   cust_date
				   ,cust_num
				   ,cust_name
				   ,[address]
				   ,city
				   ,state_id
				   ,zip
				   ,crg_CustRecNum
				   ,crg_CustSeqNum
				   ,inserted_date
				   ,inserted_by
				   ,updated_date
				   ,updated_by
				   ,esco_id
				   ,street_num
				   ,street_part
				   ,country_id
				   ,state_code
				   ,language_id
				   ,birth_date
				   ,birth_country_id
				   ,bank_reg_key
				   ,personal_tax_num
				   ,business_tax_num
				   )
				select
					@cust_date,
					@cust_num,
					@cust_name,
					@address,
					@city,
					@state_id,
					@zip,
					@crg_CustRecNum,
					@crg_CustSeqNum ,
					@inserted_date,
					@inserted_by,
					@updated_date,
					@updated_by,
					@esco_id,
					@street_num,
					@street_part,
					@country_id,
					@state_code,
					@language_id,
					@birth_date,
					@birth_country_id,
					@bank_reg_key,
				    @personal_tax_num,
				    @business_tax_num

				select @cust_id = SCOPE_IDENTITY()
			end try

			begin catch
				EXECUTE dba_InsertProcError @ProcName, @Process
			end catch			

			--update any other records in the table that have the same cust_num so it doesn't try to insert another cust record
			update c set c.cust_id = @cust_id
			from #cust c
			where c.cust_num  = @cust_num

		end

	if (@OLD_crg_CustSeqNum <> @crg_CustSeqNum) 
		begin
			set @Error = '@OLD_crg_CustSeqNum does not match @crg_CustSeqNum'
			insert into ord_proc_error (ErrorDate, ProcName,ColName,KeyValue, Error)
			select getdate(), @ProcName ,'cust_id', @cust_id , @Error
		end

	--***********not currently updating but could and for now just error things****************		
	else
		begin
			if (@OLD_crg_CustSeqNum <> @crg_CustSeqNum) 
			begin
				set @Error = '@OLD_crg_CustSeqNum does not match @crg_CustSeqNum'
				insert into ord_proc_error (ErrorDate, ProcName,ColName,KeyValue, Error)
				select getdate(), @ProcName ,'cust_id', @cust_id , @Error
			end
		end

	--update ord_cust cust_id
	set @Process = 'UPDATE cds.dbo.ord_cust'
	begin try
		update ord_cust set cust_id = @cust_id, cds_process_date = getdate() where ord_cust_id = @ord_cust_id
	end try

	begin catch
		EXECUTE dba_InsertProcError @ProcName, @Process
	end catch	

	--Insert into contact table
	set @Process = 'INSERT INTO cds.dbo.contact'
	begin try

		insert into contact
			(
			cust_id
			,emp_id
			,contact_status_id
			,contact_type_id
			,first_name
			,last_name
			,phone1
			,phone1_ext
			,phone2
			,phone2_ext
			,cell_phone
			,email1
			,email2
			,title
			,inserted_date
			,inserted_by
			,updated_date
			,updated_by
			)

			select
				@cust_id 
				,@emp_id_CDSOrdImport [emp_id]
				,@contact_status_id_ACTIVE [contact_status_id]
				,isnull(oc.ord_contact_type_id,oct.ord_contact_type_id)
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
				,'CDS_Order' [inserted_by]
				,getdate() [updated_date]
				,'CDS_Order' [updated_by]
			from ord_contact oc
			join contact_title ct on ct.contact_title_id = oc.contact_title_id
			cross join ord_contact_type oct
			where oc.ord_cust_id = @ord_cust_id 
			and oc.cds_process_date is null
			and oct.code = 'OTHER'
			and not exists(select 1 from contact c where c.cust_id = @cust_id 
							and (c.first_name = oc.first_name or c.first_name is null and oc.first_name is null) 
							and (c.last_name = oc.last_name or c.last_name is null and oc.last_name is null) 
							and (c.phone1 = oc.phone1 or c.phone1 is null and oc.phone1 is null) 
							and (c.phone1_ext = oc.phone1_ext or c.phone1_ext is null and oc.phone1_ext is null) 
							and (c.phone2 = oc.phone2 or c.phone2 is null and oc.phone2 is null) 
							and (c.phone2_ext = oc.phone2_ext or c.phone2_ext is null and oc.phone2_ext is null)
							and (c.cell_phone = oc.cell_phone or c.cell_phone is null and oc.cell_phone is null)
							and (c.email1 = oc.email1 or c.email1 is null and oc.email1 is null) 
							and (c.email2 = oc.email2 or c.email2 is null and oc.email2 is null)
							and (c.title = oc.title or c.title is null and oc.title is null)
							)

	end try

	begin catch
		EXECUTE dba_InsertProcError @ProcName, @Process
	end catch

	set @Process = 'UPDATE cds.dbo.ord_contact'
	begin try
		update oc set cds_process_date = getdate()
		from ord_contact oc
		where oc.ord_cust_id = @ord_cust_id 
		and oc.cds_process_date is null
	end try

	begin catch
		EXECUTE dba_InsertProcError @ProcName, @Process
	end catch

	--insert into cust_note table
	set @Process = 'INSERT INTO cds.dbo.cust_note'
	begin try
		insert into cust_note (cust_id, emp_id, cust_note_type_id, note_date, note)
		select @cust_id, @emp_id_CDSOrdImport [emp_id], ocnt.cust_note_type_id, ocn.note_date, ocn.note
		from ord_cust_note ocn
		join ord_cust_note_type ocnt on ocnt.ord_cust_note_type_id = ocn.ord_cust_note_type_id
		where ocn.ord_cust_id = @ord_cust_id 
		and ocn.cds_process_date is null
		and not exists(select 1 from cust_note cn where cn.cust_id = @cust_id 
						and (cn.note = ocn.note or cn.note is null and ocn.note is null)
						and (cn.note_date = ocn.note_date or cn.note_date is null and ocn.note_date is null))
	end try

	begin catch
		EXECUTE dba_InsertProcError @ProcName, @Process
	end catch

	set @Process = 'UPDATE cds.dbo.ord_cust_note'
	begin try
		update ocn set cds_process_date = getdate()
		from ord_cust_note ocn
		where ocn.ord_cust_id = @ord_cust_id 
		and ocn.cds_process_date is null
	end try

	begin catch
		EXECUTE dba_InsertProcError @ProcName, @Process
	end catch

		set @i += 1
	end
go

