resource "google_storage_bucket" "test" {
  name                        = "job_load-${local.name_suffix}_bucket"
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "test" {
  name   =  "job_load-${local.name_suffix}_bucket_object"
  source = "./test-fixtures/bigquerytable/test.parquet.gzip"
  bucket = google_storage_bucket.test.name
}

resource "google_bigquery_dataset" "test" {
  dataset_id                  = "job_load-${local.name_suffix}_dataset"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = "US"
}

resource "google_bigquery_table" "test" {
  deletion_protection = false
  table_id            = "job_load-${local.name_suffix}_table"
  dataset_id          = google_bigquery_dataset.test.dataset_id
}

resource "google_bigquery_job" "job" {
  job_id = "job_load-${local.name_suffix}"

  labels = {
    "my_job" ="load"
  }

  load {
    source_uris = [
      "gs://${google_storage_bucket_object.test.bucket}/${google_storage_bucket_object.test.name}"
    ]

    destination_table {
      project_id = google_bigquery_table.test.project
      dataset_id = google_bigquery_table.test.dataset_id
      table_id   = google_bigquery_table.test.table_id
    }

    schema_update_options = ["ALLOW_FIELD_RELAXATION", "ALLOW_FIELD_ADDITION"]
    write_disposition     = "WRITE_APPEND"
    source_format         = "PARQUET"
    autodetect            = true

    parquet_options {
      enum_as_string        = true
      enable_list_inference = true
    }
  }
}
