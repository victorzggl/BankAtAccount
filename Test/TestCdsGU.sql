use CDS
go

-- SET UP SHARE
EXEC XP_CMDSHELL 'net use T: "\\cssllc.com\dfsroot\GGLData\GGL_HQ\Div 9 - Executive\IT\Dev_Grp\Victor\TO_REVIEW\BankAtAccount" TolstayaKarova789 /USER:cssllc\VictorZ' /*TolstayaKarova789 /USER:cssllc\VictorZ*/
-- SET UP SHARE

EXEC XP_CMDSHELL 'dir /B T:\'

begin
	declare @file_path varchar(2000) = 'T:\'

	declare @xml_file_list xml
	exec tSQLt.tSQLt_GetFilesFromDirectory @file_path = @file_path, @xml_file_list = @xml_file_list out

-- 	select @xml_file_list
end
