package org.example;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class MyController {

    @PostMapping("/hello")
    public ResponseEntity<String> greet(@RequestParam int number) {
        // Logic to process the number
        return new ResponseEntity<>("Larysa's been here", HttpStatus.OK);
    }
}
