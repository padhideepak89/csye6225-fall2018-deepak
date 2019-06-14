package com.example.rest_api.Controller;

import com.example.rest_api.Entities.Attachments;
import com.example.rest_api.Service.S3AttachmentService;
import com.timgroup.statsd.StatsDClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@Profile("Dev")
public class S3AttachmentController {

    //For local attachments
    @Autowired
    S3AttachmentService s3AttachmentService;

    @Autowired
    StatsDClient statsDClient;

    final Logger logger = LoggerFactory.getLogger(S3AttachmentController.class);


    /*--------------------------------------- Services for local attachments -----------------------------*/
    @GetMapping("/transact/{transaction_id}/attachments")
    public ResponseEntity getAllAttachments(@RequestHeader(value="Authorization", defaultValue = "NoAuth")String Auth,
                                            @PathVariable(value = "transaction_id")String transactionId){
        
        statsDClient.increment("s3attachment.get");

        if(!Auth.equals("NoAuth") && !transactionId.isEmpty()){
            List<Attachments> attachmentsList = s3AttachmentService.getAllAttachments(Auth,transactionId);

            if(attachmentsList != null)
                return ResponseEntity.status(HttpStatus.OK)
                        .body(attachmentsList);

        }

        return new ResponseEntity(HttpStatus.UNAUTHORIZED);
    }

    @PostMapping("/transact/{transaction_id}/attachments")
    public ResponseEntity addAttachment(@RequestHeader(value="Authorization",defaultValue = "NoAuth")String auth,
                                        @PathVariable(value="transaction_id")String transactionId,
                                        @RequestParam("file")MultipartFile attachments){

        statsDClient.increment("s3attachment.post");
        if(!auth.equals("NoAuth") && !transactionId.isEmpty()){
            return s3AttachmentService.addAttachment(auth,transactionId,attachments);
        }

        return new ResponseEntity(HttpStatus.UNAUTHORIZED);
    }

    @PutMapping("/transact/{transaction_id}/attachments/{attachment_id}")
    public ResponseEntity updateTransaction(@RequestHeader(value="Authorization",defaultValue = "NoAuth")String auth,
                                            @PathVariable(value="transaction_id")String transactionId,
                                            @PathVariable(value="attachment_id")String attachmentId,
                                            @RequestParam("file") MultipartFile attachment){
        
        statsDClient.increment("s3Attachment.update");
        if(!auth.equals("NoAuth") && !transactionId.isEmpty() && attachment != null && !attachmentId.isEmpty()){
            return s3AttachmentService.updateAttachment(auth,transactionId,attachment,attachmentId);
        }

        return new ResponseEntity(HttpStatus.UNAUTHORIZED);
    }

    @DeleteMapping("/transact/{transaction_id}/attachments/{attachment_id}")
    public ResponseEntity deleteAttachment(@RequestHeader(value="Authorization",defaultValue = "NoAuth")String auth,
                                           @PathVariable(value="transaction_id")String transactionId,
                                           @PathVariable(value="attachment_id")String attachmentId){
        
        statsDClient.increment("s3Attachment.delete");
        if(!auth.equals("NoAuth") && !transactionId.isEmpty() && !attachmentId.isEmpty()){
            if(s3AttachmentService.deleteAttachment(auth,transactionId,attachmentId)){
                return new ResponseEntity(HttpStatus.NO_CONTENT);
            }
        }

        return new ResponseEntity(HttpStatus.UNAUTHORIZED);
    }

}
