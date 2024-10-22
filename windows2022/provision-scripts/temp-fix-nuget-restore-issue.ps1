# Note: If this takes a long time to be fixed upstream in NuGet,
# we could figure out a way to run "nuget sources" as the circleci user
# that might be able to generate the NuGet config file with the feed URL in it
# so that we don't have to specify it here
mkdir "C:\Users\circleci\AppData\Roaming\NuGet\" -force
"<configuration></configuration>" > "C:\Users\circleci\AppData\Roaming\NuGet\NuGet.Config"
nuget sources Add -Name nuget.org -Source "https://api.nuget.org/v3/index.json" -ConfigFile "C:\Users\circleci\AppData\Roaming\NuGet\NuGet.Config"
