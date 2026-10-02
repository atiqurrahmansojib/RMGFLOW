package com.rmgflow.document;

import com.rmgflow.attachment.dto.AttachmentResponse;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.dto.BuyerResponse;
import com.rmgflow.document.dto.CommercialDocumentRequest;
import com.rmgflow.document.dto.CommercialDocumentResponse;
import com.rmgflow.document.entity.DocumentEntityType;
import com.rmgflow.document.entity.DocumentStatus;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.dto.FactoryResponse;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.masterdata.entity.DocumentType;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.dto.OrderResponse;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.support.PostgresTestContainerConfig;
import com.rmgflow.support.TestUsers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/** Document 9.9/FR-130/16.1: a new upload for the same (entity, documentType) always
 * creates a new version — the prior one is never overwritten, both remain visible. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
@Import(PostgresTestContainerConfig.class)
@ActiveProfiles("test")
class CommercialDocumentFlowIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleRepository roleRepository;
    @Autowired
    private OrganizationRepository organizationRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;

    private Long uploadAttachment(String token, String filename) {
        ByteArrayResource resource = new ByteArrayResource("fake-pdf".getBytes(StandardCharsets.UTF_8)) {
            @Override
            public String getFilename() {
                return filename;
            }
        };
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        HttpHeaders fileHeaders = new HttpHeaders();
        fileHeaders.setContentType(MediaType.APPLICATION_PDF);
        body.add("file", new HttpEntity<>(resource, fileHeaders));
        HttpHeaders headers = TestUsers.bearer(token);
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        AttachmentResponse attachment = restTemplate.exchange(
                "/api/v1/attachments?entityType=ORDER&entityId=1", HttpMethod.POST,
                new HttpEntity<>(body, headers), AttachmentResponse.class).getBody();
        return attachment.id();
    }

    @Test
    void reuploadingTheSameDocumentType_createsANewVersion_bothRemainVisible() {
        String token = TestUsers.createAndLogin(restTemplate, userRepository, roleRepository, organizationRepository, passwordEncoder, "GENERAL_MANAGER").accessToken();

        BuyerRequest buyerRequest = new BuyerRequest("BYR-" + UUID.randomUUID(), "Document Test Buyer", null, null, null, null, null, null);
        BuyerResponse buyer = restTemplate.exchange("/api/v1/buyers", HttpMethod.POST,
                new HttpEntity<>(buyerRequest, TestUsers.bearer(token)), BuyerResponse.class).getBody();
        StyleRequest styleRequest = new StyleRequest("STY-" + UUID.randomUUID(), buyer.id(), null, "Blazer", null, null, null);
        StyleResponse style = restTemplate.exchange("/api/v1/styles", HttpMethod.POST,
                new HttpEntity<>(styleRequest, TestUsers.bearer(token)), StyleResponse.class).getBody();
        FactoryRequest factoryRequest = new FactoryRequest("FAC-" + UUID.randomUUID(), "Document Test Factory",
                PartnerType.GARMENT_FACTORY, null, null, null, null, null);
        FactoryResponse factory = restTemplate.exchange("/api/v1/factories", HttpMethod.POST,
                new HttpEntity<>(factoryRequest, TestUsers.bearer(token)), FactoryResponse.class).getBody();
        restTemplate.exchange("/api/v1/factories/" + factory.id() + "/buyer-approvals", HttpMethod.PUT,
                new HttpEntity<>(new FactoryBuyerApprovalRequest(buyer.id(), FactoryBuyerApprovalStatus.APPROVED, LocalDate.now(), null), TestUsers.bearer(token)),
                Void.class);
        OrderItemRequest item = new OrderItemRequest(style.id(), factory.id(), "Navy", "40", 50, new BigDecimal("12.00"));
        OrderRequest orderRequest = new OrderRequest("PO-" + UUID.randomUUID(), buyer.id(), null, LocalDate.now(), null, null,
                null, null, null, "USD", false, null, List.of(item));
        OrderResponse order = restTemplate.exchange("/api/v1/orders", HttpMethod.POST,
                new HttpEntity<>(orderRequest, TestUsers.bearer(token)), OrderResponse.class).getBody();

        DocumentType[] documentTypes = restTemplate.exchange("/api/v1/document-types", HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), DocumentType[].class).getBody();
        long commercialInvoiceTypeId = findByName(documentTypes, "Commercial Invoice").getId();

        Long firstAttachmentId = uploadAttachment(token, "invoice-v1.pdf");
        CommercialDocumentRequest firstRequest = new CommercialDocumentRequest(DocumentEntityType.ORDER, order.id(), commercialInvoiceTypeId, firstAttachmentId, null);
        ResponseEntity<CommercialDocumentResponse> firstResponse = restTemplate.exchange("/api/v1/documents", HttpMethod.POST,
                new HttpEntity<>(firstRequest, TestUsers.bearer(token)), CommercialDocumentResponse.class);
        assertThat(firstResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(firstResponse.getBody().versionNo()).isEqualTo(1);

        Long secondAttachmentId = uploadAttachment(token, "invoice-v2-corrected.pdf");
        CommercialDocumentRequest secondRequest = new CommercialDocumentRequest(DocumentEntityType.ORDER, order.id(), commercialInvoiceTypeId, secondAttachmentId, LocalDate.now().plusYears(1));
        ResponseEntity<CommercialDocumentResponse> secondResponse = restTemplate.exchange("/api/v1/documents", HttpMethod.POST,
                new HttpEntity<>(secondRequest, TestUsers.bearer(token)), CommercialDocumentResponse.class);
        assertThat(secondResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(secondResponse.getBody().versionNo()).isEqualTo(2);

        List<CommercialDocumentResponse> all = List.of(restTemplate.exchange(
                "/api/v1/documents?entityType=ORDER&entityId=" + order.id(), HttpMethod.GET,
                new HttpEntity<>(TestUsers.bearer(token)), CommercialDocumentResponse[].class).getBody());
        assertThat(all).hasSize(2);
        assertThat(all).extracting(CommercialDocumentResponse::fileAttachmentId)
                .containsExactlyInAnyOrder(firstAttachmentId, secondAttachmentId);

        ResponseEntity<CommercialDocumentResponse> approveResponse = restTemplate.exchange(
                "/api/v1/documents/" + secondResponse.getBody().id() + "/approve", HttpMethod.POST,
                new HttpEntity<>(TestUsers.bearer(token)), CommercialDocumentResponse.class);
        assertThat(approveResponse.getBody().status()).isEqualTo(DocumentStatus.APPROVED);
    }

    private DocumentType findByName(DocumentType[] types, String name) {
        for (DocumentType type : types) {
            if (type.getName().equals(name)) return type;
        }
        throw new IllegalStateException("Document type not found: " + name);
    }
}
