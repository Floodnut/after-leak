const AWS = require('aws-sdk');
const https = require('https');
const lambda = new AWS.Lambda();


let regions = ["global",
           "us-east-1",
           "us-east-2",
           "us-west-1",
           "us-west-2",
           "ap-south-1",
           "ap-northeast-3",
           "ap-northeast-2",
           "ap-southeast-1",
           "ap-southeast-2",
           "ap-northeast-1",
           "ca-central-1",
           "eu-central-1",
           "eu-west-1",
           "eu-west-2",
           "eu-west-3",
           "eu-north-1",
           "sa-east-1"]


exports.handler = async (event) => {

    var postData = JSON.stringify({
        'content' : event['target_account'] + ' account nuke started'
    });
    
    var options = {
      hostname: 'discord.com',
      port: 443,
      path: '__your_discord_webhook_url__',
      method: 'POST',
      headers: {
           'Content-Type': 'application/json',
           'Content-Length': postData.length
         }
    };
    
    var req = https.request(options, (res) => {
      console.log('statusCode:', res.statusCode);
      console.log('headers:', res.headers);
    
      res.on('data', (d) => {
        process.stdout.write(d);
      });
    });
    
    
    req.on('error', (e) => {
      console.error(e);
    });
    
    req.write(postData);
    req.end();

    for (let region in regions) {
        var lambda_event = {
            "access-key-id": process.env[event['target_account']+"_access_key_id"],
            "secret-access-key": process.env[event['target_account']+"_secret_access_key"],
            "region": regions[region],
            "target_account": event['target_account']
        }
        
        console.log(lambda_event)
    
    var params = {
        FunctionName: 'nuke',
        Payload: JSON.stringify(lambda_event)
    };

    lambda.invoke(params, (error, data) => {});
    
    await new Promise(r => setTimeout(r, 3000));
  }

    const response = {
        statusCode: 200,
        body: JSON.stringify('buste from Lambda!'),
    };
    return response;
};
