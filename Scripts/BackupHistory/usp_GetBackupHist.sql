USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetBackupHist]    Script Date: 12/4/2017 11:14:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[usp_GetBackupHist] 
as
Select distinct top 10000 t1.name
,       (dense_rank() over (order by backup_start_date desc,t3.backup_set_id))%2 as l1
,       (dense_rank() over (order by backup_start_date desc,t3.backup_set_id,t6.physical_device_name))%2 as l2
,       t3.user_name
,       t3.backup_set_id
,       t3.name as backup_name
,       t3.description
,       (datediff( ss, t3.backup_start_date, t3.backup_finish_date))/60.0 as duration
,       t3.backup_start_date
,       t3.backup_finish_date
,       t3.type as [type]
,       case when (t3.backup_size/1024.0) < 1024 then (t3.backup_size/1024.0) 
                when (t3.backup_size/1048576.0) < 1024 then (t3.backup_size/1048576.0) 
        else (t3.backup_size/1048576.0/1024.0) 
        end as backup_size 
,       case when (t3.backup_size/1024.0) < 1024 then 'KB' 
                when (t3.backup_size/1048576.0) < 1024 then 'MB' 
        else 'GB' 
        end as backup_size_unit 
,       t3.first_lsn
,       t3.last_lsn
,       case when t3.differential_base_lsn is null then 'Not Applicable' 
        else convert( varchar(100),t3.differential_base_lsn) 
        end as [differential_base_lsn]
,       t6.physical_device_name
,       t6.device_type as [device_type]
,       t3.recovery_model  
from sys.databases t1 
inner join backupset t3 on (t3.database_name = t1.name )  
left outer join backupmediaset t5 on ( t3.media_set_id = t5.media_set_id ) 
left outer join backupmediafamily t6 on ( t6.media_set_id = t5.media_set_id ) 
--where (t1.name = @DatabaseName) 
order by backup_start_date desc,t3.backup_set_id,t6.physical_device_name;  
 
