package com.example.rest_api.Controller;

import com.example.rest_api.Service.ResponseService;
import com.example.rest_api.Service.UserService;
import com.example.rest_api.Service.ValidationService;
import com.timgroup.statsd.StatsDClient;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
public class AuthorizationController {

    @Autowired
    UserService userService;

    @Autowired
    ValidationService validateService;

    @Autowired
    ResponseService responseService;
    
    @Autowired
    StatsDClient statsDClient;

    final Logger logger = LoggerFactory.getLogger(AuthorizationController.class);


    @RequestMapping(value="/time", method = RequestMethod.GET)
    public ResponseEntity authAndLogin(@RequestHeader(value="Authorization", defaultValue = "NoValueFound")String auth){
        
        statsDClient.increment("time.get");   
        if(auth.isEmpty() || auth.equals("NoValueFound")){
            return responseService.generateResponse(HttpStatus.UNAUTHORIZED,
                    "{\"Response\":\"You are not logged in\"}");
        }

        return userService.authUser(auth);

    }

    @RequestMapping(value="/user/register",method=RequestMethod.POST)
    public ResponseEntity register(@RequestHeader(value="Authorization")String auth){
        
        statsDClient.increment("user.create");

        if(auth.isEmpty() || auth.equals("NoValueFound")){
            return responseService.generateResponse(HttpStatus.UNAUTHORIZED,
                        "{\"Response\":\"Please enter username and password\"}");
        }

        return userService.createUser(auth);

    }

    
    @GetMapping("/user/reset")
    public ResponseEntity resetPassword(@RequestParam("EmailId")String emailId){

        statsDClient.increment("user.reset.password");

        if(emailId.isEmpty()){
            return responseService.generateResponse(HttpStatus.UNAUTHORIZED,
                    "{\"Response\":\"Please enter email\"}");
        }

        return userService.resetPassword(emailId);

    }

}
