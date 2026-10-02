package com.rmgflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

/** Document 13: @EnableScheduling backs the automation jobs (e.g.
 * TaMilestoneOverdueScanService) that run on a cron schedule. */
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class RmgflowApplication {

	public static void main(String[] args) {
		SpringApplication.run(RmgflowApplication.class, args);
	}

}
