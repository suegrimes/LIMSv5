# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180515193622) do

  create_table "adapters", id: :integer, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "runtype_adapter", limit: 25
    t.string "mplex_splex", limit: 1
    t.string "multi_indices", limit: 1
    t.string "index_position", limit: 2
    t.string "index1_prefix", limit: 2
    t.string "index2_prefix", limit: 2
    t.string "tag_prefix", limit: 2
    t.string "tag_suffix", limit: 2
    t.integer "tag_length", limit: 2
    t.timestamp "updated_at"
  end

  create_table "align_qc", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "flow_lane_id", null: false
    t.string "sequencing_key", limit: 50
    t.integer "lane_nr", limit: 1
    t.integer "lane_yield"
    t.integer "clusters_raw"
    t.integer "clusters_pf"
    t.integer "cycle1_intensity_pf"
    t.integer "cycle20_intensity_pct_pf"
    t.decimal "pct_pf_clusters", precision: 6, scale: 2
    t.decimal "pct_align_pf", precision: 6, scale: 2
    t.decimal "align_score_pf", precision: 8, scale: 2
    t.decimal "pct_error_rate_pf", precision: 6, scale: 2
    t.integer "nr_NM"
    t.integer "nr_QC"
    t.integer "nr_RX"
    t.integer "nr_U0"
    t.integer "nr_U1"
    t.integer "nr_U2"
    t.integer "nr_UM"
    t.integer "nr_nonuniques"
    t.integer "nr_uniques"
    t.integer "min_insert", limit: 2
    t.integer "max_insert", limit: 2
    t.integer "median_insert", limit: 2
    t.integer "total_reads"
    t.integer "pf_reads"
    t.integer "failed_reads"
    t.integer "total_errors"
    t.integer "consistent_unique_bp"
    t.decimal "consistent_unique_pct", precision: 4, scale: 1
    t.integer "rescued_bp"
    t.decimal "rescued_pct", precision: 4, scale: 1
    t.integer "total_consistent_bp"
    t.decimal "total_consistent_pct", precision: 4, scale: 1
    t.integer "pf_unique_bp"
    t.decimal "pf_unique_pct", precision: 4, scale: 1
    t.string "notes"
    t.datetime "created_at"
    t.timestamp "updated_at"
    t.index ["flow_lane_id"], name: "qc_flow_lane_fk"
  end

  create_table "alignment_refs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "alignment_key", limit: 20, null: false
    t.string "interface_name", limit: 25
    t.string "genome_build", limit: 50
    t.integer "created_by"
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "assigned_barcodes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.date "assign_date"
    t.string "group_name", limit: 30
    t.string "owner_name", limit: 25
    t.string "sample_type", limit: 25
    t.integer "start_barcode", limit: 3, null: false
    t.integer "end_barcode", limit: 3, null: false
    t.datetime "created_at"
    t.integer "updated_by"
  end

  create_table "attached_files", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "sampleproc_id", null: false
    t.string "sampleproc_type", limit: 50, null: false
    t.string "document"
    t.string "document_content_type", limit: 40
    t.string "document_file_size", limit: 25
    t.string "notes"
    t.integer "updated_by"
    t.datetime "created_at"
  end

  create_table "categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "cgroup_id"
    t.string "category", limit: 50, null: false
    t.string "category_description"
    t.string "archive_flag", limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "category_values", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "category_id", null: false
    t.integer "c_position"
    t.string "c_value", limit: 50, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cgroups", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "group_name", limit: 25, null: false
    t.integer "sort_order", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "consent_protocols", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "consent_nr", limit: 8
    t.string "consent_name", limit: 100
    t.string "consent_abbrev", limit: 50
    t.string "email_confirm_to"
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "flow_cells", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.date "flowcell_date"
    t.string "nr_bases_read1", limit: 4
    t.string "nr_bases_index", limit: 2
    t.string "nr_bases_index1", limit: 2
    t.string "nr_bases_index2", limit: 2
    t.string "nr_bases_read2", limit: 4
    t.string "cluster_kit", limit: 10
    t.string "sequencing_kit", limit: 10
    t.string "flowcell_status", limit: 2
    t.string "sequencing_key", limit: 50
    t.string "run_description", limit: 80
    t.date "sequencing_date"
    t.integer "seq_machine_id"
    t.integer "seq_run_nr", limit: 2
    t.string "machine_type", limit: 10
    t.string "hiseq_xref", limit: 50
    t.string "notes"
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "flow_lanes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "flow_cell_id", null: false
    t.integer "seq_lib_id"
    t.string "sequencing_key", limit: 50
    t.string "machine_type", limit: 10
    t.string "lib_barcode", limit: 20
    t.string "lib_name", limit: 50
    t.integer "lane_nr", limit: 1, null: false
    t.float "lib_conc", limit: 24
    t.string "lib_conc_uom", limit: 6
    t.integer "adapter_id"
    t.string "runtype_adapter", limit: 20
    t.integer "pool_id", limit: 3
    t.string "oligo_pool", limit: 8
    t.integer "alignment_ref_id"
    t.string "alignment_ref", limit: 50
    t.string "notes"
    t.datetime "created_at"
    t.timestamp "updated_at"
    t.index ["flow_cell_id"], name: "fl_flow_cell_fk"
    t.index ["seq_lib_id"], name: "fl_seq_lib_fk"
  end

  create_table "freezer_locations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "room_nr", limit: 25, null: false
    t.string "freezer_nr", limit: 25
    t.string "freezer_type", limit: 20
    t.string "long_term_storage", limit: 1
    t.string "owner_name", limit: 25
    t.string "owner_email", limit: 50
    t.string "comments"
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "histologies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "sample_id"
    t.string "he_barcode_key", limit: 20, null: false
    t.date "he_date"
    t.string "histopathology", limit: 25
    t.string "he_classification", limit: 50
    t.string "pathologist", limit: 50
    t.decimal "tumor_cell_content", precision: 7, scale: 3
    t.string "inflammation_type", limit: 25
    t.string "inflammation_infiltration", limit: 25
    t.string "comments"
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "index_tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "adapter_id", limit: 2
    t.string "runtype_adapter", limit: 25
    t.integer "index_read", limit: 1
    t.integer "tag_nr", limit: 2
    t.string "tag_sequence", limit: 12
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "items", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "order_id"
    t.string "po_number", limit: 20
    t.string "requester_name", limit: 30
    t.string "deliver_site", limit: 4
    t.string "item_description"
    t.string "company_name", limit: 50
    t.string "catalog_nr", limit: 50
    t.string "chemical_flag", limit: 1
    t.string "item_size", limit: 50
    t.string "item_quantity", limit: 25
    t.string "item_quote", limit: 100
    t.decimal "item_price", precision: 9, scale: 2
    t.string "item_received", limit: 1
    t.string "grant_nr", limit: 30
    t.string "notes"
    t.datetime "created_at"
    t.timestamp "updated_at"
    t.integer "updated_by", limit: 2
    t.index ["order_id"], name: "it_order_fk"
  end

  create_table "lib_samples", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "seq_lib_id"
    t.integer "splex_lib_id"
    t.string "splex_lib_barcode", limit: 20
    t.integer "processed_sample_id"
    t.string "sample_name", limit: 50
    t.string "source_DNA", limit: 50
    t.string "runtype_adapter", limit: 50
    t.integer "index_tag", limit: 2
    t.integer "adapter_id", limit: 2
    t.integer "index1_tag_id"
    t.integer "index2_tag_id"
    t.string "enzyme_code", limit: 50
    t.string "notes"
    t.integer "updated_by"
    t.datetime "created_at"
    t.timestamp "updated_at"
    t.index ["seq_lib_id"], name: "ls_seq_lib_id"
  end

  create_table "machine_incidents", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "seq_machine_id"
    t.date "incident_date", null: false
    t.string "incident_description", null: false
    t.integer "updated_by"
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "molecular_assays", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "barcode_key", limit: 20, null: false
    t.integer "processed_sample_id"
    t.integer "protocol_id"
    t.string "owner", limit: 25
    t.date "preparation_date"
    t.integer "volume", limit: 2
    t.decimal "concentration", precision: 8, scale: 3
    t.string "plate_number", limit: 25
    t.string "plate_coord", limit: 4
    t.string "notes"
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "orders", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "company_name", limit: 50
    t.string "order_quote", limit: 100
    t.date "date_ordered"
    t.string "po_number", limit: 20
    t.string "rpo_or_cwa", limit: 6
    t.string "incl_chemicals", limit: 1
    t.string "order_received", limit: 1
    t.string "order_number", limit: 20
    t.string "notes"
    t.datetime "created_at"
    t.timestamp "updated_at"
    t.integer "updated_by", limit: 2
  end

  create_table "pathologies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "patient_id", null: false
    t.date "collection_date"
    t.date "pathology_date"
    t.string "pathologist", limit: 50
    t.string "general_pathology", limit: 25
    t.string "pathology_classification", limit: 100
    t.string "tumor_stage", limit: 2
    t.string "xrt_flag", limit: 2
    t.string "t_code", limit: 2
    t.string "n_code", limit: 2
    t.string "m_code", limit: 2
    t.string "comments"
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "patients", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.binary "clinical_id_encrypted", limit: 30
    t.string "organism", limit: 25
    t.string "gender", limit: 1
    t.string "ethnicity", limit: 35
    t.string "race", limit: 70
    t.binary "hipaa_encrypted", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "processed_samples", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "sample_id"
    t.integer "patient_id"
    t.integer "protocol_id"
    t.string "extraction_type", limit: 25
    t.date "processing_date"
    t.string "input_uom", limit: 25
    t.decimal "input_amount", precision: 11, scale: 3
    t.string "barcode_key", limit: 25
    t.string "old_barcode", limit: 25
    t.string "support", limit: 25
    t.string "elution_buffer", limit: 25
    t.string "vial", limit: 10
    t.decimal "final_vol", precision: 11, scale: 3
    t.decimal "final_conc", precision: 11, scale: 3
    t.decimal "final_a260_a280", precision: 11, scale: 3
    t.decimal "final_a260_a230", precision: 11, scale: 3
    t.decimal "final_rin_nr", precision: 4, scale: 1
    t.string "psample_remaining", limit: 2
    t.integer "storage_location_id"
    t.string "storage_shelf", limit: 10
    t.string "storage_boxbin", limit: 25
    t.string "comments"
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["barcode_key"], name: "ps_barcode_idx"
    t.index ["sample_id"], name: "ps_sample_fk"
  end

  create_table "protocols", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "protocol_name", limit: 50
    t.string "protocol_abbrev", limit: 25
    t.string "protocol_version", limit: 10
    t.string "protocol_type", limit: 1
    t.string "protocol_code", limit: 3
    t.string "reference", limit: 100
    t.string "comments"
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "publication_authors", primary_key: ["publication_id", "researcher_id"], force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "publication_id", null: false
    t.integer "researcher_id", null: false
  end

  create_table "publication_lanes", primary_key: ["publication_id", "flow_lane_id"], force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "publication_id", default: 0, null: false
    t.integer "flow_lane_id", default: 0, null: false
  end

  create_table "publications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "title_abbrev", limit: 50, null: false
    t.string "title_full"
    t.string "publication_name", limit: 50, null: false
    t.date "date_published"
    t.string "comments"
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "researchers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "user_id"
    t.string "researcher_name", limit: 50, null: false
    t.string "researcher_initials", limit: 3, null: false
    t.string "company", limit: 50
    t.string "phone_number", limit: 20
    t.string "active_inactive", limit: 1
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "run_dirs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "flow_cell_id", null: false
    t.string "sequencing_key", limit: 50
    t.integer "storage_device_id", limit: 2, null: false
    t.string "device_name", limit: 25
    t.string "rdir_name", limit: 50
    t.integer "file_count"
    t.decimal "total_size_gb", precision: 6, scale: 2
    t.date "date_sized"
    t.date "date_copied"
    t.integer "copied_by", limit: 2
    t.date "date_verified"
    t.integer "verified_by", limit: 2
    t.string "delete_flag", limit: 1
    t.date "date_deleted"
    t.string "notes"
    t.integer "updated_by", limit: 2
    t.timestamp "updated_at"
  end

  create_table "sample_characteristics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "patient_id"
    t.date "collection_date"
    t.string "clinic_or_location", limit: 100
    t.integer "consent_protocol_id"
    t.string "consent_nr", limit: 15
    t.string "gender", limit: 1
    t.string "ethnicity", limit: 35
    t.string "race", limit: 70
    t.string "nccc_tumor_id", limit: 20
    t.string "nccc_pathno", limit: 20
    t.integer "pathology_id"
    t.string "pathology", limit: 50
    t.string "comments"
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sample_storage_containers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "stored_sample_id"
    t.string "stored_sample_type", limit: 50
    t.string "sample_name_or_barcode", limit: 25, default: "", null: false
    t.string "container_type", limit: 15
    t.string "container_name", limit: 25, default: "", null: false
    t.string "position_in_container", limit: 15
    t.integer "freezer_location_id"
    t.integer "storage_container_id"
    t.string "xx_row_nr", limit: 2
    t.string "xx_position_nr", limit: 3, default: ""
    t.string "notes", limit: 100
    t.integer "updated_by", limit: 2
    t.timestamp "updated_at"
    t.index ["stored_sample_id"], name: "cn_sample_idx"
  end

  create_table "samples", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.integer "patient_id"
    t.integer "sample_characteristic_id"
    t.integer "source_sample_id"
    t.string "source_barcode_key", limit: 20
    t.string "barcode_key", limit: 20, null: false
    t.string "alt_identifier", limit: 20, comment: "NCCC new path no"
    t.date "sample_date"
    t.string "sample_type", limit: 50
    t.string "sample_tissue", limit: 50
    t.string "left_right", limit: 1
    t.string "tissue_preservation", limit: 25
    t.string "tumor_normal", limit: 25
    t.string "sample_container", limit: 20
    t.string "vial_type", limit: 30
    t.decimal "amount_initial", precision: 10, scale: 3, default: "0.0"
    t.decimal "amount_rem", precision: 10, scale: 3, default: "0.0"
    t.string "amount_uom", limit: 20
    t.string "sample_remaining", limit: 2
    t.integer "storage_location_id"
    t.string "storage_shelf", limit: 10
    t.string "storage_boxbin", limit: 25
    t.string "comments", limit: 1024
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["patient_id"], name: "smp_patient_fk"
    t.index ["sample_characteristic_id"], name: "smp_sample_characteristic_fk"
  end

  create_table "seq_libs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "barcode_key", limit: 20
    t.string "lib_name", limit: 50, null: false
    t.string "library_type", limit: 2
    t.string "lib_status", limit: 2
    t.integer "protocol_id"
    t.string "owner", limit: 25
    t.date "preparation_date"
    t.integer "adapter_id", limit: 2
    t.string "runtype_adapter", limit: 25
    t.string "project", limit: 50
    t.integer "pool_id", limit: 3
    t.string "oligo_pool", limit: 8
    t.integer "alignment_ref_id"
    t.string "alignment_ref", limit: 50
    t.integer "trim_bases", limit: 2
    t.decimal "sample_conc", precision: 15, scale: 9
    t.string "sample_conc_uom", limit: 10
    t.decimal "lib_conc_requested", precision: 15, scale: 9
    t.string "lib_conc_uom", limit: 10
    t.string "notebook_ref", limit: 50
    t.string "notes"
    t.string "quantitation_method", limit: 20
    t.decimal "starting_amt_ng", precision: 11, scale: 3
    t.integer "pcr_size", limit: 2
    t.decimal "dilution", precision: 6, scale: 3
    t.integer "updated_by", limit: 2
    t.datetime "created_at"
    t.timestamp "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "seq_machines", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "machine_name", limit: 20, null: false
    t.string "bldg_location", limit: 12
    t.string "machine_type", limit: 20
    t.string "machine_desc", limit: 50
    t.integer "last_seq_num", limit: 2
    t.string "notes"
    t.datetime "created_at"
    t.timestamp "updated_at"
  end

  create_table "storage_containers", id: :integer, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "container_type", limit: 15
    t.string "container_name", limit: 25
    t.integer "freezer_location_id"
    t.string "freezer_type", limit: 20
    t.string "notes"
  end

  create_table "storage_devices", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "device_name", limit: 25, null: false
    t.string "building_loc", limit: 25
    t.string "base_run_dir", limit: 50
    t.date "last_upd_of_runs"
    t.integer "updated_by", limit: 2
    t.timestamp "updated_at"
  end

  create_table "storage_types", id: :integer, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "container_type", limit: 15, null: false
    t.integer "nr_rows", limit: 2
    t.integer "nr_cols", limit: 2
    t.string "first_row", limit: 1
    t.string "first_col", limit: 1
    t.string "freezer_type", limit: 20
    t.string "notes"
    t.string "display_format", limit: 8
  end

  create_table "user_logins", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "ip_address", limit: 20, null: false
    t.integer "user_id", limit: 2
    t.string "user_login", limit: 25, null: false
    t.datetime "login_timestamp"
    t.datetime "logout_timestamp"
  end

  create_table "user_logs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT" do |t|
    t.string "ip_address", limit: 20
    t.integer "user_id", limit: 2
    t.string "user_login", limit: 25, null: false
    t.string "controller_name", limit: 25, null: false
    t.string "action_name", limit: 25, null: false
    t.datetime "log_timestamp", null: false
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.string "login", limit: 25
    t.string "email"
    t.string "active_inactive", limit: 1
    t.string "crypted_password", limit: 40
    t.string "salt", limit: 40
    t.string "reset_code", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
  end

  add_foreign_key "align_qc", "flow_lanes", name: "align_qc_ibfk_1"
  add_foreign_key "flow_lanes", "flow_cells", name: "flow_lanes_ibfk_2"
  add_foreign_key "flow_lanes", "seq_libs", name: "flow_lanes_ibfk_1"
  add_foreign_key "items", "orders", name: "items_ibfk_1"
  add_foreign_key "lib_samples", "seq_libs", name: "lib_samples_ibfk_1"
  add_foreign_key "processed_samples", "samples", name: "processed_samples_ibfk_1"
  add_foreign_key "samples", "sample_characteristics", name: "samples_ibfk_1"
end
