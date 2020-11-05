struc BPB
    .oem_name:              resb 8
    .bytes_per_sector:      resw 1
    .sectors_per_cluster:   resb 1
    .reserved_sector_count: resw 1
    .table_count:           resb 1
    .root_entry_count:      resw 1
    .total_sectors_16:      resw 1
    .media_type:            resb 1
    .table_size_16:         resw 1
    .sectors_per_track:     resw 1
    .head_side_count:       resw 1
    .hidden_sector_count:   resd 1
    .total_sectors_32:      resd 1
endstruc

struc BPB_Ext32
    .table_size_32:         resd 1
    .extended_flags:        resw 1
    .fat_version:           resw 1
    .root_cluster:          resd 1
    .fat_info:              resw 1
    .backup_BS_sector:      resw 1
    resb 12
    .drive_number:          resb 1
    resb 1
    .boot_signature:        resb 1
    .volume_id:             resd 1
    .volume_label:          resb 11
    .fat_type_label:        resb 8
endstruc