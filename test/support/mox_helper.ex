Mox.defmock(ExZipProtect.Adapters.S3ClientMock, for: ExZipProtect.Adapters.S3Client)

# Use the mock by default in test env
Application.put_env(:ex_zip_protect, :s3_client, ExZipProtect.Adapters.S3ClientMock)
