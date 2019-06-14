package example;

import com.amazonaws.regions.Regions;
import com.amazonaws.services.cloudwatch.AmazonCloudWatch;
import com.amazonaws.services.cloudwatch.AmazonCloudWatchClientBuilder;
import com.amazonaws.services.cloudwatch.model.*;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClient;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.Table;
import com.amazonaws.services.dynamodbv2.model.*;
import com.amazonaws.services.dynamodbv2.model.ResourceNotFoundException;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.amazonaws.services.simpleemail.AmazonSimpleEmailService;
import com.amazonaws.services.simpleemail.AmazonSimpleEmailServiceClientBuilder;
import com.amazonaws.services.simpleemail.model.*;
import javafx.scene.control.Tab;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;

public class forgotpassword implements RequestHandler<SNSEvent, String> {


    static AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard().build();

    static DynamoDB dynamoDb = new DynamoDB(client);

    static String functionName = System.getenv("Func_Name");

    //Temporary table
    static String tableName = System.getenv("Table_Name");

    static String fromAddress = System.getenv("From_Addr");

    static String hostAddress = System.getenv("Host_Name");
    
    static String ttlValue = System.getenv("TTL");

    static DynamoDBMapper mapper = new DynamoDBMapper(client);

    static int snsMetric = 0;
    static int sesMetric = 0;
    static int lambdaMetric = 0;
    static int dynamodbMetric = 0;
    static String to = "";
    static String token = "";

    @Override
    public String handleRequest(SNSEvent message, Context context){

        lambdaMetric++;

        Table table = null;

        try{
            table = dynamoDb.getTable(tableName);
            table.describe();
            //Increment DynamoDB metric count
            dynamodbMetric++;

        }catch(ResourceNotFoundException ex){
            try {
                table = createTable(dynamoDb);

                //Increment DynamoDB metric count
                dynamodbMetric++;

            } catch (Exception exc) {
                exc.printStackTrace();
                //return table.getDescription().toString();
            }
        }

        String dynamoDBTableName = table.getTableName();
        String snsTopicName = null;

        try{

                SNSEvent.SNSRecord record = message.getRecords().get(0);

                String topicArn = record.getSNS().getTopicArn();

                int index = topicArn.lastIndexOf(":");

                snsTopicName = topicArn.substring(index+1,topicArn.length());

                //event message contains email id and token sent from web api
                String eventMessage = record.getSNS().getMessage();

                //If no sns message then stop the program and return empty value
                if(eventMessage.isEmpty() || eventMessage == null){
                    return "";
                }

                //Increment SNS metric count
                snsMetric++;

                //store email id and token in an array
                String mailAndToken[] = eventMessage.trim().split(",");
                to = mailAndToken[0];
                token = mailAndToken[1];

                Map<String,AttributeValue> key_to_get = new HashMap<String,AttributeValue>();
                key_to_get.put("EmailId",new AttributeValue(mailAndToken[0]));


                //Get the existing email id and token from table
                GetItemRequest request = new GetItemRequest()
                        .withKey(key_to_get)
                        .withTableName(tableName);

               Map<String,AttributeValue> item = client.getItem(request).getItem();

                //Increment DynamoDB metric count
                dynamodbMetric++;

                //If not item exists
                if (item == null) {

                    Date date = new Date();

                    //long ttl = 20 * 60 * 1000;
                    
                    int ttl = Integer.parseInt(ttlValue);

                   Calendar calendar = Calendar.getInstance();
                   calendar.setTime(date);
                   calendar.add(calendar.MINUTE,ttl);


                    //create new item
                    Item newItem = new Item().withPrimaryKey("EmailId", mailAndToken[0])
                                        .withString("Token",mailAndToken[1])
                                        .with("TimeTolive",calendar.getTimeInMillis()/1000L);


                    table.putItem(newItem);
                    //Increment DynamoDB metric count
                    dynamodbMetric++;

                    //Build Email (SES) data

                    final String subject = "Link to reset password - Expense tracker application";

                    final String htmlbody = "<h2>Hi,</h2>"
                            + "<br/><p>It seems you requested for a password reset. Please click on the following link to reset your password</p>"
                            + "<br/>Reset Link => "+hostAddress+"/reset_email?id="+  to + "&token="+token
                            +"<br/><p><b>Disclaimer:</b>This link will only be valid for 20 mins</p>"
                            + "<br/><br/>Regards,<br/>TrackXpense Team";

                    sendEmail(to,fromAddress,subject,htmlbody);

                    //Increment ses metric count
                    sesMetric++;

                    //Create custom metric

                    //Lambda metric
                    updateMetric("with function name",functionName,
                            "Lambda Access",(double)lambdaMetric,"CSYE6225-Lambda");

                    //dynamoDB metric
                    updateMetric("with table name",dynamoDBTableName,
                            "DynamoDB Access",(double)dynamodbMetric,"CSYE6225-DynamoDB");

                    //SNS metric
                    updateMetric("with topic name",snsTopicName,
                            "SNS Access",(double)snsMetric,"CSYE6225-SNS");

                    //SES metric
                    updateMetric("mail","Send",
                            "SES Access",(double)sesMetric,"CSYE6225-SES");


                    return "Success - Item created.";

                }
        }catch (Exception exception){
            System.err.println("Items failed.");
            exception.printStackTrace();
            return "Error";
        }

        return "Item already exists";

    }

    public void sendEmail(String to, String from, String subject, String htmlbody){
        try{

            AmazonSimpleEmailService client = AmazonSimpleEmailServiceClientBuilder.standard()
                    .withRegion(Regions.US_EAST_1).build();

            SendEmailRequest request = new SendEmailRequest()
                    .withDestination(new Destination().withToAddresses(to))
                    .withMessage(new Message()
                    .withBody(new Body()
                    .withHtml(new Content()
                    .withCharset("UTF-8").withData(htmlbody)))
                    .withSubject(new Content()
                    .withCharset("UTF-8").withData(subject)))
                    .withSource(from);

            client.sendEmail(request);
            System.err.print("Email Sent");
        }catch(Exception e){
            System.err.println("Email not sent");
            e.printStackTrace();
        }
    }

    public void updateMetric(String dimensionName, String dimensionValue, String metricName, double metricValue, String namespace){

        final AmazonCloudWatch cw = AmazonCloudWatchClientBuilder.defaultClient();

        try {

            //Build lambda metric
            Dimension dimension = new Dimension()
                    .withName(dimensionName)
                    .withValue(dimensionValue);

            MetricDatum datum = new MetricDatum()
                    .withMetricName(metricName)
                    .withUnit(StandardUnit.Count)
                    .withValue(metricValue)
                    .withDimensions(dimension);

            PutMetricDataRequest request = new PutMetricDataRequest()
                    .withNamespace(namespace)
                    .withMetricData(datum);

            PutMetricDataResult response = cw.putMetricData(request);

        }catch(Exception e){
            System.err.print(e.getMessage());
            e.printStackTrace();
        }

    }

    public Table createTable(DynamoDB dynamoDB) throws InterruptedException {
        List<AttributeDefinition> attributeDefinitions= new ArrayList<AttributeDefinition>();
        attributeDefinitions.add(new AttributeDefinition().withAttributeName("EmailId").withAttributeType("S"));

        List<KeySchemaElement> keySchema = new ArrayList<KeySchemaElement>();
        keySchema.add(new KeySchemaElement().withAttributeName("EmailId").withKeyType(KeyType.HASH));

        CreateTableRequest request = new CreateTableRequest()
                .withTableName(tableName)
                .withKeySchema(keySchema)
                .withAttributeDefinitions(attributeDefinitions)
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(6L));

        Table table = dynamoDB.createTable(request);
        table.waitForActive();

        return table;
    }

}
