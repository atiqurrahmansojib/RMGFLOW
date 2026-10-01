package com.rmgflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class RmgflowApplication {

	public static void main(String[] args) {
		SpringApplication.run(RmgflowApplication.class, args);
	}

}
