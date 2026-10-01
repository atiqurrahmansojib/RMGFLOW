package com.rmgflow;

import com.rmgflow.support.PostgresTestContainerConfig;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class RmgflowApplicationTests {

	@Test
	void contextLoads() {
	}

}
