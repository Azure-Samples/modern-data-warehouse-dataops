keyvaultlsname = 'Ls_KeyVault_01'
adls2lsname = 'Ls_AdlsGen2_01'

from pyspark.sql import SparkSession

sc = SparkSession.builder.getOrCreate()
token_library = sc._jvm.com.microsoft.azure.synapse.tokenlibrary.TokenLibrary
storage_account = token_library.getSecretWithLS(keyvaultlsname, "datalakeaccountname")

spark.conf.set("spark.storage.synapse.linkedServiceName", adls2lsname)
spark.conf.set("fs.azure.account.oauth.provider.type", "com.microsoft.azure.synapse.tokenlibrary.LinkedServiceBasedTokenProvider")