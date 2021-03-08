FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS runtime
WORKDIR /app


FROM mcr.microsoft.com/dotnet/sdk:5.0-alpine AS sdk


FROM sdk AS build
ARG CODE_VERSION=not_defined
WORKDIR /src
ADD Test Test/
ADD TestRunnerProject TestRunnerProject/
COPY NotBuilding.sln .
RUN dotnet build "Test" --no-dependencies -c Release -o /app /clp:PerformanceSummary /p:RunCodeAnalysis=False /p:EnableNETAnalyzers=False


FROM runtime AS app-test
EXPOSE 80
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Test.dll"]


FROM build AS testrunner
WORKDIR /
RUN mkdir /.build
RUN cp -avr /app/* /.build
RUN dotnet build TestRunnerProject --no-dependencies -c Release -o /.build /clp:PerformanceSummary /p:RunCodeAnalysis=False /p:EnableNETAnalyzers=False
ENTRYPOINT ["dotnet", "test", "/.build/*.Tests.dll", "--logger", "console;verbosity=detailed", "--verbosity", "minimal", "--no-build", "--no-restore"]
