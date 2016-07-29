# PCF Support Utilites

Tools for support report aggregation

## PCF Report Aggregator

Currently supported reports to be collected automatically:

* Recent installation events in Ops Manager.
* Installation logs providing installation IDs.
* BOSH task logs providing task IDs. This includes `--event`, `--cpi`, `--debug` and `--result` logs.
* Current deployed BOSH deployments.
* Current BOSH instances reports. Including `--details`, `--dns`, `--ps` and `--vitals` information.
* Job and agent logs for BOSH managed VMs.

### Prerequisities

Run in Pivotal Cloud Foundry Operations Manager. Currently compatible with version 1.7+.

You need to have your admin credentials for Ops Manager in order to run the aggregator. No other credentials/information needed.

### Usage

#### Using CURL

```
bash -c "$(curl https://raw.githubusercontent.com/pivotal-gss/support-log/master/report-aggregator.sh)"
```

#### Download and run

If your Ops Manager does not have Internet access you may download the report-aggregator.sh, scp onto the Ops Manager VM, then run

```
chmod +x report-aggregator.sh
bash report-aggregator.sh
```

After collected all the needed reports, scp out the report tarball for further diagnosis.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## TODO

Automatically uploading the aggregated reports to the support storage. Thus there will be no additional effort for file transferring.

