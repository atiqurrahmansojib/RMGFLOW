package com.rmgflow.config;

import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfWriter;
import com.rmgflow.activity.dto.ActivityRequest;
import com.rmgflow.activity.entity.ActivityType;
import com.rmgflow.activity.service.ActivityService;
import com.rmgflow.approval.dto.ApprovalDecisionRequest;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;
import com.rmgflow.approval.service.ApprovalService;
import com.rmgflow.attachment.service.AttachmentService;
import com.rmgflow.buyer.dto.BuyerContactRequest;
import com.rmgflow.buyer.dto.BuyerRequest;
import com.rmgflow.buyer.service.BuyerContactService;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.claim.dto.ClaimRequest;
import com.rmgflow.claim.dto.ClaimResolutionRequest;
import com.rmgflow.claim.entity.ClaimRaisedBy;
import com.rmgflow.claim.entity.ClaimStatus;
import com.rmgflow.claim.entity.ClaimType;
import com.rmgflow.claim.service.ClaimService;
import com.rmgflow.costing.dto.CostingItemRequest;
import com.rmgflow.costing.dto.CostingRequest;
import com.rmgflow.costing.entity.CostingComponentType;
import com.rmgflow.costing.service.CostingService;
import com.rmgflow.document.dto.CommercialDocumentRequest;
import com.rmgflow.document.entity.DocumentEntityType;
import com.rmgflow.document.service.CommercialDocumentService;
import com.rmgflow.factory.dto.FactoryBuyerApprovalRequest;
import com.rmgflow.factory.dto.FactoryCapabilityRequest;
import com.rmgflow.factory.dto.FactoryCertificationRequest;
import com.rmgflow.factory.dto.FactoryContactRequest;
import com.rmgflow.factory.dto.FactoryRequest;
import com.rmgflow.factory.entity.FactoryBuyerApprovalStatus;
import com.rmgflow.factory.entity.PartnerType;
import com.rmgflow.factory.repository.FactoryRepository;
import com.rmgflow.factory.service.FactoryBuyerApprovalService;
import com.rmgflow.factory.service.FactoryCapabilityService;
import com.rmgflow.factory.service.FactoryCertificationService;
import com.rmgflow.factory.service.FactoryContactService;
import com.rmgflow.factory.service.FactoryService;
import com.rmgflow.financial.dto.OrderFinancialsRequest;
import com.rmgflow.financial.dto.PayableRequest;
import com.rmgflow.financial.dto.PaymentRecordRequest;
import com.rmgflow.financial.dto.ReceivableRequest;
import com.rmgflow.financial.service.OrderFinancialsService;
import com.rmgflow.financial.service.PayableService;
import com.rmgflow.financial.service.PaymentRecordService;
import com.rmgflow.financial.service.ReceivableService;
import com.rmgflow.identity.entity.Assignment;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.Role;
import com.rmgflow.identity.entity.ScopeType;
import com.rmgflow.identity.entity.User;
import com.rmgflow.identity.repository.AssignmentRepository;
import com.rmgflow.identity.repository.OrganizationRepository;
import com.rmgflow.identity.repository.RoleRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateRequest;
import com.rmgflow.inquiry.dto.InquiryFactoryCandidateStatusRequest;
import com.rmgflow.inquiry.dto.InquiryRequest;
import com.rmgflow.inquiry.dto.MarkWonLostRequest;
import com.rmgflow.inquiry.entity.InquiryFactoryCandidateStatus;
import com.rmgflow.inquiry.entity.InquiryStatus;
import com.rmgflow.inquiry.service.InquiryFactoryCandidateService;
import com.rmgflow.inquiry.service.InquiryService;
import com.rmgflow.masterdata.entity.Season;
import com.rmgflow.masterdata.repository.DefectTypeRepository;
import com.rmgflow.masterdata.repository.DocumentTypeRepository;
import com.rmgflow.masterdata.repository.MilestoneTypeRepository;
import com.rmgflow.masterdata.repository.PaymentTermRepository;
import com.rmgflow.masterdata.repository.SeasonRepository;
import com.rmgflow.notification.repository.NotificationRepository;
import com.rmgflow.notification.service.NotificationService;
import com.rmgflow.order.dto.OrderAmendmentRequest;
import com.rmgflow.order.dto.OrderItemRequest;
import com.rmgflow.order.dto.OrderRequest;
import com.rmgflow.order.entity.OrderStatus;
import com.rmgflow.order.repository.OrderRepository;
import com.rmgflow.order.service.OrderAmendmentService;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.production.dto.ProductionUpdateRequest;
import com.rmgflow.production.service.ProductionUpdateService;
import com.rmgflow.quality.dto.CapaFactoryResponseRequest;
import com.rmgflow.quality.dto.CapaRecordRequest;
import com.rmgflow.quality.dto.DefectRequest;
import com.rmgflow.quality.dto.InspectionRequest;
import com.rmgflow.quality.entity.InspectionResult;
import com.rmgflow.quality.entity.InspectionType;
import com.rmgflow.quality.service.CapaRecordService;
import com.rmgflow.quality.service.DefectService;
import com.rmgflow.quality.service.InspectionService;
import com.rmgflow.quotation.dto.QuotationRequest;
import com.rmgflow.quotation.entity.QuotationStatus;
import com.rmgflow.quotation.service.QuotationService;
import com.rmgflow.sample.dto.SampleRequest;
import com.rmgflow.sample.dto.SampleRevisionRequest;
import com.rmgflow.sample.repository.SampleRepository;
import com.rmgflow.sample.repository.SampleTypeRepository;
import com.rmgflow.sample.service.SampleRevisionService;
import com.rmgflow.sample.service.SampleService;
import com.rmgflow.security.AuthenticatedUser;
import com.rmgflow.shipment.dto.ShipmentRequest;
import com.rmgflow.shipment.entity.ShipmentStatus;
import com.rmgflow.shipment.repository.ShipmentRepository;
import com.rmgflow.shipment.service.ShipmentService;
import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleRevisionRequest;
import com.rmgflow.style.service.StyleRevisionService;
import com.rmgflow.style.service.StyleService;
import com.rmgflow.ta.dto.RecordActualDateRequest;
import com.rmgflow.ta.dto.TaTemplateMilestoneRequest;
import com.rmgflow.ta.dto.TaTemplateRequest;
import com.rmgflow.ta.entity.TaMilestone;
import com.rmgflow.ta.repository.TaMilestoneRepository;
import com.rmgflow.ta.service.TaMilestoneService;
import com.rmgflow.ta.service.TaTemplateService;
import com.rmgflow.task.dto.TaskRequest;
import com.rmgflow.task.entity.TaskPriority;
import com.rmgflow.task.entity.TaskStatus;
import com.rmgflow.task.service.TaskItemService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Opt-in demo dataset (DEMO_DATA=true) so a tester can log in as any of the 12
 * Doc 5.1 roles and see realistic data on every screen and every Doc 14 report.
 *
 * Deliberately goes through the real services (acting as the appropriate demo user)
 * rather than raw SQL, so business rules, approval rounds, immutability triggers,
 * T&A instantiation/cascade and the shipment quality gate all behave exactly as they
 * would for real users. The only direct repository writes are for things no service
 * exposes (users/assignments, order IN_PROGRESS/CLOSED status, readable document
 * numbers, milestone responsible factory). All dates are relative to today so My Day,
 * overdue and delay views always have something to show.
 *
 * Idempotent: skipped when the marker user {@value #MARKER_EMAIL} already exists. The
 * whole dataset is written in one transaction, so a failure leaves nothing half-seeded.
 */
@Component
@org.springframework.core.annotation.Order(2)
@RequiredArgsConstructor
public class DemoDataSeeder implements ApplicationRunner {

    public static final String MARKER_EMAIL = "demo.admin@rmgflow.test";
    public static final String DEMO_PASSWORD = "Demo@1234";

    private static final Logger log = LoggerFactory.getLogger(DemoDataSeeder.class);
    private static final ZoneId DHAKA = ZoneId.of("Asia/Dhaka");
    private static final BigDecimal USD_BDT = new BigDecimal("121.50");

    // ---- infrastructure
    private final PlatformTransactionManager transactionManager;
    private final PasswordEncoder passwordEncoder;
    private final OrganizationRepository organizationRepository;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AssignmentRepository assignmentRepository;
    private final SeasonRepository seasonRepository;
    private final PaymentTermRepository paymentTermRepository;
    private final MilestoneTypeRepository milestoneTypeRepository;
    private final DefectTypeRepository defectTypeRepository;
    private final DocumentTypeRepository documentTypeRepository;
    private final SampleTypeRepository sampleTypeRepository;
    private final OrderRepository orderRepository;
    private final ShipmentRepository shipmentRepository;
    private final SampleRepository sampleRepository;
    private final FactoryRepository factoryRepository;
    private final TaMilestoneRepository taMilestoneRepository;
    private final NotificationRepository notificationRepository;

    // ---- business services
    private final BuyerService buyerService;
    private final BuyerContactService buyerContactService;
    private final FactoryService factoryService;
    private final FactoryContactService factoryContactService;
    private final FactoryCapabilityService factoryCapabilityService;
    private final FactoryCertificationService factoryCertificationService;
    private final FactoryBuyerApprovalService factoryBuyerApprovalService;
    private final InquiryService inquiryService;
    private final InquiryFactoryCandidateService inquiryFactoryCandidateService;
    private final StyleService styleService;
    private final StyleRevisionService styleRevisionService;
    private final AttachmentService attachmentService;
    private final CostingService costingService;
    private final QuotationService quotationService;
    private final ApprovalService approvalService;
    private final SampleService sampleService;
    private final SampleRevisionService sampleRevisionService;
    private final OrderService orderService;
    private final OrderAmendmentService orderAmendmentService;
    private final TaTemplateService taTemplateService;
    private final TaMilestoneService taMilestoneService;
    private final ProductionUpdateService productionUpdateService;
    private final InspectionService inspectionService;
    private final DefectService defectService;
    private final CapaRecordService capaRecordService;
    private final ShipmentService shipmentService;
    private final CommercialDocumentService commercialDocumentService;
    private final OrderFinancialsService orderFinancialsService;
    private final ReceivableService receivableService;
    private final PayableService payableService;
    private final PaymentRecordService paymentRecordService;
    private final ClaimService claimService;
    private final ActivityService activityService;
    private final TaskItemService taskItemService;
    private final NotificationService notificationService;

    @Value("${rmgflow.demo-data.enabled:false}")
    private boolean enabled;

    // ---- per-run state (the seeder runs once per JVM; reset at the start of seed())
    private final Map<String, User> users = new LinkedHashMap<>();
    private final Map<String, Authentication> sessions = new HashMap<>();
    private final Map<String, Long> buyers = new LinkedHashMap<>();
    private final Map<String, Long> factories = new LinkedHashMap<>();
    private final Map<String, Long> styles = new LinkedHashMap<>();
    private final Map<String, Long> inquiries = new LinkedHashMap<>();
    private final Map<String, Long> approvedCostings = new HashMap<>();
    private final Map<String, Long> orders = new LinkedHashMap<>();
    private final Map<String, String> orderFactory = new HashMap<>();
    private final Map<String, Long> shipments = new HashMap<>();
    private final Map<String, Integer> counts = new LinkedHashMap<>();
    private Long organizationId;
    private LocalDate today;
    private int orderSeq;
    private int shipmentSeq;
    private int sampleSeq;

    @Override
    public void run(ApplicationArguments args) {
        if (!enabled) {
            return;
        }
        if (userRepository.existsByEmailIgnoreCase(MARKER_EMAIL)) {
            log.info("Demo data already present ({} exists) — skipping", MARKER_EMAIL);
            return;
        }
        try {
            new TransactionTemplate(transactionManager).executeWithoutResult(status -> seed());
        } finally {
            SecurityContextHolder.clearContext();
        }
        log.info("Demo data seeded into organization {}: {}", organizationId, counts);
    }

    /** Per-module row counts from the last successful run (for logging/tests). */
    public Map<String, Integer> lastRunCounts() {
        return Map.copyOf(counts);
    }

    private void seed() {
        users.clear(); sessions.clear(); buyers.clear(); factories.clear(); styles.clear(); inquiries.clear();
        approvedCostings.clear(); orders.clear(); orderFactory.clear(); shipments.clear(); counts.clear();
        orderSeq = 0; shipmentSeq = 0; sampleSeq = 0;
        today = LocalDate.now();

        organizationId = resolveOrganization();
        seedSeasons();
        seedUsers();
        seedBuyers();
        seedFactories();
        seedAssignments();
        seedStyles();
        seedInquiries();
        seedCostingsAndQuotations();
        seedSamples();
        seedTaTemplates();
        seedOrders();
        seedFinancials();
        seedClaims();
        seedCommunication();
        seedOverdueMilestoneNotifications();
    }

    // =================================================================== foundation

    private Long resolveOrganization() {
        return organizationRepository.findAll().stream()
                .map(Organization::getId)
                .min(Comparator.naturalOrder())
                .orElseGet(() -> {
                    Organization org = new Organization();
                    org.setName("RMGFlow Demo Buying House");
                    return organizationRepository.save(org).getId();
                });
    }

    private void seedSeasons() {
        int year = today.getYear();
        seasonIfMissing("Spring/Summer", year, LocalDate.of(year, 2, 1), LocalDate.of(year, 7, 31));
        seasonIfMissing("Autumn/Winter", year, LocalDate.of(year, 8, 1), LocalDate.of(year + 1, 1, 31));
        seasonIfMissing("Spring/Summer", year + 1, LocalDate.of(year + 1, 2, 1), LocalDate.of(year + 1, 7, 31));
    }

    private void seasonIfMissing(String name, int year, LocalDate start, LocalDate end) {
        boolean exists = seasonRepository.findAll().stream().anyMatch(s -> s.getName().equals(name) && s.getYear() == year);
        if (!exists) {
            Season season = new Season();
            season.setName(name);
            season.setYear(year);
            season.setStartDate(start);
            season.setEndDate(end);
            seasonRepository.save(season);
            count("Seasons");
        }
    }

    private Long season(String name, int yearOffset) {
        int year = today.getYear() + yearOffset;
        return seasonRepository.findAll().stream()
                .filter(s -> s.getName().equals(name) && s.getYear() == year)
                .map(Season::getId).findFirst().orElseThrow();
    }

    private void seedUsers() {
        user("admin", MARKER_EMAIL, "Demo Super Admin", "SUPER_ADMIN", "+8801711000001");
        user("owner", "owner@rmgflow.test", "Rafiqul Islam", "OWNER_MD", "+8801711000002");
        user("gm", "gm@rmgflow.test", "Shahana Akter", "GENERAL_MANAGER", "+8801711000003");
        user("srm", "sr.merch@rmgflow.test", "Tanvir Hasan", "SENIOR_MERCHANDISER", "+8801711000004");
        user("jrm", "jr.merch@rmgflow.test", "Nusrat Jahan", "JUNIOR_MERCHANDISER", "+8801711000005");
        user("smp", "sampling@rmgflow.test", "Mahmudul Karim", "SAMPLING_COORDINATOR", "+8801711000006");
        user("prod", "production@rmgflow.test", "Abdul Mannan", "PRODUCTION_FOLLOWUP", "+8801711000007");
        user("qa", "quality@rmgflow.test", "Farhana Rahman", "QUALITY_INSPECTOR", "+8801711000008");
        user("com", "commercial@rmgflow.test", "Imran Chowdhury", "COMMERCIAL_EXECUTIVE", "+8801711000009");
        user("acc", "accounts@rmgflow.test", "Sabina Yasmin", "ACCOUNTS_FINANCE", "+8801711000010");
        user("fc", "factory.coord@rmgflow.test", "Jahidul Alam", "FACTORY_COORDINATOR", "+8801711000011");
        user("view", "viewer@rmgflow.test", "Kamal Uddin", "MANAGEMENT_VIEWER", "+8801711000012");
    }

    private void user(String key, String email, String fullName, String roleName, String phone) {
        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new IllegalStateException("Role " + roleName + " missing — check V2 migration ran"));
        User user = new User();
        user.setOrganization(organizationRepository.getReferenceById(organizationId));
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(DEMO_PASSWORD));
        user.setFullName(fullName);
        user.setPhone(phone);
        user.setRoles(Set.of(role));
        user = userRepository.save(user);
        users.put(key, user);

        // Same principal + authorities shape JwtAuthenticationFilter builds for a real request.
        List<GrantedAuthority> authorities = new ArrayList<>();
        authorities.add(new SimpleGrantedAuthority("ROLE_" + roleName));
        roleRepository.findPermissionCodesByRoleNames(Set.of(roleName))
                .forEach(code -> authorities.add(new SimpleGrantedAuthority(code)));
        AuthenticatedUser principal = new AuthenticatedUser(user.getId(), organizationId, email, Set.of(roleName));
        sessions.put(key, new UsernamePasswordAuthenticationToken(principal, null, authorities));
        count("Users");
    }

    /** Every subsequent service call runs as this demo user (audit trail, created_by, permission checks). */
    private void as(String userKey) {
        SecurityContextHolder.getContext().setAuthentication(sessions.get(userKey));
    }

    private Long uid(String userKey) {
        return users.get(userKey).getId();
    }

    // =================================================================== partners

    private void seedBuyers() {
        as("srm");
        Long lc30 = paymentTerm("L/C 30 DAYS");
        Long lcSight = paymentTerm("L/C AT SIGHT");
        Long tt = paymentTerm("T/T AFTER SHIPMENT");
        Long oa60 = paymentTerm("OPEN ACCOUNT 60 DAYS");

        buyer("NVK", "NVK-SE", "Nordvik Apparel AB", "Nordvik Group", "SE", "EUR", lc30, "FOB",
                new String[]{"Elin Lindqvist", "Sourcing", "elin.lindqvist@nordvik.example", "+46 8 555 0101"},
                new String[]{"Oskar Berg", "Quality", "oskar.berg@nordvik.example", "+46 8 555 0102"});
        buyer("BWC", "BWC-US", "Brightwater Clothing Co.", "Brightwater Holdings", "US", "USD", tt, "FOB",
                new String[]{"Megan Brooks", "Merchandising", "megan.brooks@brightwater.example", "+1 212 555 0141"},
                new String[]{"Daniel Reyes", "Technical Design", "daniel.reyes@brightwater.example", "+1 212 555 0142"});
        buyer("MLM", "MLM-FR", "Maison Lumiere SARL", null, "FR", "EUR", lcSight, "FOB",
                new String[]{"Camille Durand", "Buying", "camille.durand@maisonlumiere.example", "+33 1 55 50 1010"},
                new String[]{"Hugo Martin", "Compliance", "hugo.martin@maisonlumiere.example", "+33 1 55 50 1011"});
        buyer("KST", "KST-DE", "Kestrel Outdoor GmbH", "Kestrel Group", "DE", "EUR", lc30, "FCA",
                new String[]{"Jonas Weber", "Sourcing", "jonas.weber@kestrel.example", "+49 40 555 2020"},
                new String[]{"Lena Fischer", "QA", "lena.fischer@kestrel.example", "+49 40 555 2021"});
        buyer("TRW", "TRW-GB", "Thames & Rowe Ltd", null, "GB", "GBP", oa60, "FOB",
                new String[]{"Olivia Hughes", "Buying", "olivia.hughes@thamesrowe.example", "+44 20 5550 3030"},
                new String[]{"James Patel", "Technical", "james.patel@thamesrowe.example", "+44 20 5550 3031"});
        buyer("PCB", "PCB-CA", "Pacific Coast Basics Inc.", "PCB Retail", "CA", "USD", tt, "FOB",
                new String[]{"Sarah Chen", "Product Development", "sarah.chen@pcbasics.example", "+1 604 555 0177"},
                new String[]{"Ryan Thompson", "Logistics", "ryan.thompson@pcbasics.example", "+1 604 555 0178"});
    }

    private void buyer(String key, String code, String name, String group, String country, String currency,
                       Long paymentTermsId, String incoterm, String[]... contacts) {
        Long id = buyerService.create(new BuyerRequest(code, name, group, country, currency, paymentTermsId, incoterm, null)).id();
        buyers.put(key, id);
        count("Buyers");
        boolean first = true;
        for (String[] c : contacts) {
            buyerContactService.create(id, new BuyerContactRequest(c[0], c[1], c[2], c[3], first));
            first = false;
            count("Buyer contacts");
        }
    }

    private void seedFactories() {
        as("gm");
        factory("GZP", "KNT-GZP", "Gazipur Knit Composite Ltd", PartnerType.GARMENT_FACTORY,
                "Gazipur Knit Composite Limited", "Plot 14, BSCIC Industrial Estate, Konabari, Gazipur", 450_000,
                List.of("T-Shirts", "Polo Shirts", "Fleece"), "Md. Shafiqul Islam", "Merchandising Manager", "+8801819100101");
        factory("NGJ", "WVN-NGJ", "Narayanganj Woven Garments Ltd", PartnerType.GARMENT_FACTORY,
                "Narayanganj Woven Garments Limited", "Fatullah BSCIC, Narayanganj", 220_000,
                List.of("Shirts", "Blouses"), "Rezaul Karim", "Production Manager", "+8801819100202");
        factory("SVR", "SWT-SVR", "Savar Sweaters Ltd", PartnerType.GARMENT_FACTORY,
                "Savar Sweaters Limited", "Dhaka EPZ, Ganakbari, Savar, Dhaka", 180_000,
                List.of("Sweaters", "Cardigans"), "Anisur Rahman", "GM Operations", "+8801819100303");
        factory("CTGD", "DNM-CTG", "Chattogram Denim Mills Ltd", PartnerType.GARMENT_FACTORY,
                "Chattogram Denim Mills Limited", "Sector 5, CEPZ, Chattogram", 300_000,
                List.of("Denim Bottoms", "Denim Jackets"), "Tarek Aziz", "Head of Merchandising", "+8801819100404");
        factory("ASH", "KNT-ASH", "Ashulia Fashion Knitwear Ltd", PartnerType.GARMENT_FACTORY,
                "Ashulia Fashion Knitwear Limited", "Zirabo, Ashulia, Savar, Dhaka", 260_000,
                List.of("T-Shirts", "Kidswear", "Fleece"), "Monir Hossain", "Factory Manager", "+8801819100505");
        factory("CTGW", "WVN-CTG", "Karnaphuli Shirts Ltd", PartnerType.GARMENT_FACTORY,
                "Karnaphuli Shirts Limited", "KEPZ, Anwara, Chattogram", 200_000,
                List.of("Chinos", "Sleepwear", "Shirts"), "Sohel Rana", "Merchandising Manager", "+8801819100606");
        factory("FFW", "FFW-CTG", "Bay Logistics Ltd", PartnerType.FREIGHT_FORWARDER,
                "Bay Logistics Limited", "Agrabad C/A, Chattogram", null,
                List.of("Sea Freight", "Air Freight"), "Nazmul Haque", "Operations Head", "+8801819100707");
        factory("LAB", "LAB-DHK", "Dhaka Textile Testing Lab", PartnerType.TESTING_LAB,
                "Dhaka Textile Testing Laboratory Ltd", "Tejgaon I/A, Dhaka", null,
                List.of("Fabric Testing", "Colour Fastness"), "Dr. Selina Parvin", "Lab Manager", "+8801819100808");

        // Compliance certificates — a mix of valid, expiring soon and expired (Doc 14 document-expiry report).
        cert("GZP", "BSCI Audit (Grade B)", -345, 20);
        cert("GZP", "OEKO-TEX Standard 100", -160, 205);
        cert("NGJ", "WRAP Gold", -300, 65);
        cert("SVR", "WRAP Platinum", -380, -15);
        cert("SVR", "BSCI Audit (Grade A)", -200, 165);
        cert("CTGD", "GOTS", -90, 275);
        cert("CTGD", "RSC Structural & Fire Safety", -330, 35);
        cert("ASH", "Sedex SMETA 4-Pillar", -350, 12);
        cert("CTGW", "ISO 9001:2015", -500, 230);

        // Doc 9.4 factory-buyer approvals: the hard gate checked at order creation.
        approval("GZP", "NVK", FactoryBuyerApprovalStatus.APPROVED, -400, 330);
        approval("GZP", "KST", FactoryBuyerApprovalStatus.APPROVED, -300, 430);
        approval("GZP", "PCB", FactoryBuyerApprovalStatus.APPROVED, -250, 480);
        approval("NGJ", "BWC", FactoryBuyerApprovalStatus.APPROVED, -380, 350);
        approval("NGJ", "MLM", FactoryBuyerApprovalStatus.APPROVED, -200, 530);
        approval("SVR", "MLM", FactoryBuyerApprovalStatus.APPROVED, -420, 310);
        approval("SVR", "TRW", FactoryBuyerApprovalStatus.APPROVED, -310, 420);
        approval("CTGD", "KST", FactoryBuyerApprovalStatus.APPROVED, -280, 450);
        approval("CTGD", "BWC", FactoryBuyerApprovalStatus.APPROVED, -260, 470);
        approval("CTGD", "PCB", FactoryBuyerApprovalStatus.EXPIRED, -760, -30);
        approval("ASH", "KST", FactoryBuyerApprovalStatus.APPROVED, -190, 540);
        approval("ASH", "PCB", FactoryBuyerApprovalStatus.PENDING, null, null);
        approval("ASH", "NVK", FactoryBuyerApprovalStatus.REJECTED, null, null);
        approval("CTGW", "TRW", FactoryBuyerApprovalStatus.APPROVED, -500, 230);
        approval("CTGW", "PCB", FactoryBuyerApprovalStatus.APPROVED, -330, 400);
    }

    private void factory(String key, String code, String name, PartnerType type, String legalName, String address,
                         Integer capacity, List<String> capabilities, String contactName, String contactRole, String phone) {
        Long id = factoryService.create(new FactoryRequest(code, name, type, legalName, address, "BD", capacity, null)).id();
        factories.put(key, id);
        count("Factories / partners");
        String domain = code.toLowerCase().replace("-", "") + ".example";
        factoryContactService.create(id, new FactoryContactRequest(contactName, contactRole, "contact@" + domain, phone, true));
        factoryContactService.create(id, new FactoryContactRequest("Compliance Desk", "Compliance Officer", "compliance@" + domain,
                phone.substring(0, phone.length() - 1) + "9", false));
        count("Factory contacts", 2);
        for (String capability : capabilities) {
            factoryCapabilityService.create(id, new FactoryCapabilityRequest(capability));
            count("Factory capabilities");
        }
    }

    private void cert(String factoryKey, String name, int issuedOffset, int expiryOffset) {
        factoryCertificationService.create(factories.get(factoryKey),
                new FactoryCertificationRequest(name, day(issuedOffset), day(expiryOffset), null));
        count("Factory certifications");
    }

    private void approval(String factoryKey, String buyerKey, FactoryBuyerApprovalStatus status, Integer approvedOffset, Integer expiryOffset) {
        factoryBuyerApprovalService.upsert(factories.get(factoryKey), new FactoryBuyerApprovalRequest(buyers.get(buyerKey), status,
                approvedOffset != null ? day(approvedOffset) : null, expiryOffset != null ? day(expiryOffset) : null));
        count("Factory-buyer approvals");
    }

    /** Doc 5.3 object-level scoping for the non-"see everything" roles, so their lists and reports aren't empty. */
    private void seedAssignments() {
        for (String userKey : List.of("srm", "smp", "prod", "qa", "com")) {
            buyers.values().forEach(id -> assign(userKey, ScopeType.BUYER, id));
        }
        for (String userKey : List.of("smp", "prod", "qa", "com")) {
            factories.values().forEach(id -> assign(userKey, ScopeType.FACTORY, id));
        }
        assign("jrm", ScopeType.BUYER, buyers.get("NVK"));
        assign("jrm", ScopeType.BUYER, buyers.get("BWC"));
        assign("jrm", ScopeType.BUYER, buyers.get("PCB"));
        // The factory coordinator is the liaison for the Gazipur knit unit only.
        assign("fc", ScopeType.FACTORY, factories.get("GZP"));
    }

    private void assign(String userKey, ScopeType type, Long scopeId) {
        if (assignmentRepository.existsByUserIdAndScopeTypeAndScopeId(users.get(userKey).getId(), type, scopeId)) {
            return; // e.g. a merchandiser is auto-assigned to the buyers they created
        }
        Assignment assignment = new Assignment();
        assignment.setUser(users.get(userKey));
        assignment.setScopeType(type);
        assignment.setScopeId(scopeId);
        assignmentRepository.save(assignment);
        count("Assignments");
    }

    // =================================================================== product development

    private void seedStyles() {
        as("srm");
        Long ss = season("Spring/Summer", 0);
        Long aw = season("Autumn/Winter", 0);
        Long ssNext = season("Spring/Summer", 1);

        style("S1", "NVK-SS26-TS101", "NVK", "NV-24871", "T-Shirts", ss, "Men", "Men's crew neck tee, single jersey, chest print",
                rev("Single jersey", "100% combed cotton", "160", "White / Navy", "S-XXL"),
                rev("Single jersey", "100% combed cotton (BCI)", "165", "White / Navy / Heather Grey", "S-XXL"));
        style("S2", "NVK-AW26-PL204", "NVK", "NV-25102", "Polo Shirts", aw, "Men", "Men's pique polo with embroidered logo",
                rev("Pique", "100% cotton", "220", "Black / Bottle Green", "S-XXL"));
        style("S3", "BWC-SS26-SH310", "BWC", "BW-OX-310", "Shirts", ss, "Men", "Men's oxford button-down shirt, enzyme wash",
                rev("Oxford 40s", "100% cotton", "125", "Light Blue / White", "S-XL"),
                rev("Oxford 40s", "100% cotton", "125", "Light Blue / White / Pink", "S-XXL"),
                rev("Oxford 40s", "100% cotton, wrinkle-free finish", "125", "Light Blue / White / Pink", "S-XXL"));
        style("S4", "BWC-AW26-DJ120", "BWC", "BW-DJ-120", "Denim Bottoms", aw, "Women", "Women's slim fit stretch jeans",
                rev("Stretch denim 11oz", "98% cotton 2% elastane", "373", "Mid Indigo", "24-34"));
        style("S5", "MLM-AW26-SW050", "MLM", "ML-SW-050", "Sweaters", aw, "Women", "Women's 12GG crew neck pullover",
                rev("12GG flat knit", "70% cotton 30% acrylic", null, "Ecru / Camel", "XS-XL"),
                rev("12GG flat knit", "70% cotton 30% recycled acrylic", null, "Ecru / Camel / Bordeaux", "XS-XL"));
        style("S6", "MLM-SS27-BL077", "MLM", "ML-BL-077", "Blouses", ssNext, "Women", "Women's printed viscose blouse",
                rev("Viscose challis", "100% LENZING ECOVERO viscose", "110", "Floral print AOP", "34-44"));
        style("S7", "KST-AW26-DN501", "KST", "KS-501", "Denim Bottoms", aw, "Men", "Men's 5-pocket regular fit denim",
                rev("Rigid denim 12.5oz", "100% organic cotton", "424", "Dark Rinse", "28-38"));
        style("S8", "KST-AW26-HD330", "KST", "KS-330", "Fleece", aw, "Unisex", "Brushed fleece pullover hoodie",
                rev("3-thread fleece", "80% cotton 20% polyester", "300", "Charcoal / Olive", "XS-XXL"));
        style("S9", "TRW-SS26-CH210", "TRW", "TR-CH-210", "Chinos", ss, "Men", "Men's slim chino, garment washed",
                rev("Cotton twill", "98% cotton 2% elastane", "240", "Stone / Navy / Khaki", "28-38"));
        style("S10", "TRW-AW26-CD015", "TRW", "TR-CD-015", "Cardigans", aw, "Women", "Women's 7GG button cardigan",
                rev("7GG flat knit", "60% cotton 40% wool", null, "Oatmeal / Forest", "XS-XL"),
                rev("7GG flat knit", "60% cotton 40% RWS wool", null, "Oatmeal / Forest", "XS-XL"));
        style("S11", "PCB-SS26-TK440", "PCB", "PC-440", "Kidswear", ss, "Kids", "Kids' printed tank top",
                rev("Single jersey", "100% cotton", "140", "Assorted prints", "2-10Y"));
        style("S12", "PCB-SS26-PJ900", "PCB", "PC-900", "Sleepwear", ss, "Women", "Women's woven pyjama set (top + pant)",
                rev("Cotton poplin", "100% cotton", "115", "Blue stripe / Pink check", "XS-XL"));

        // Tech packs as real (tiny) PDFs, so attachment download/open works end to end.
        as("jrm");
        for (String key : List.of("S1", "S2", "S3", "S4", "S5", "S6", "S7", "S9")) {
            attach("STYLE", styles.get(key), "TechPack-" + key + ".pdf", "Tech pack — style " + key,
                    "Construction, measurement chart (graded), BOM and artwork placement.");
        }
    }

    private StyleRevisionRequest rev(String fabric, String composition, String gsm, String color, String sizeRange) {
        String spec = "{\"chest\":{\"M\":52,\"tolerance\":1},\"length\":{\"M\":72,\"tolerance\":1},\"unit\":\"cm\"}";
        return new StyleRevisionRequest(fabric, composition, gsm != null ? new BigDecimal(gsm) : null, color, sizeRange, spec);
    }

    private void style(String key, String styleNo, String buyerKey, String buyerStyleNo, String category, Long seasonId,
                       String gender, String description, StyleRevisionRequest... revisions) {
        Long id = styleService.create(new StyleRequest(styleNo, buyers.get(buyerKey), buyerStyleNo, category, seasonId, gender, description)).id();
        styles.put(key, id);
        count("Styles");
        for (StyleRevisionRequest revision : revisions) {
            styleRevisionService.create(id, revision);
            count("Style revisions");
        }
    }

    private void seedInquiries() {
        Long ss = season("Spring/Summer", 0);
        Long aw = season("Autumn/Winter", 0);
        Long ssNext = season("Spring/Summer", 1);
        as("srm");
        inquiry("I1", "INQ-DEMO-101", "NVK", ssNext, "jrm", 30000, "2.40", "USD", 150, null, null, "GZP", "ASH");
        inquiry("I2", "INQ-DEMO-102", "BWC", ss, "srm", 8000, "6.80", "USD", 60, InquiryStatus.QUOTED, null, "NGJ", "CTGW");
        inquiry("I3", "INQ-DEMO-103", "MLM", aw, "srm", 6000, "10.20", "EUR", 40, InquiryStatus.WON, null, "SVR");
        inquiry("I4", "INQ-DEMO-104", "KST", aw, "srm", 10000, "10.60", "EUR", 30, InquiryStatus.WON, null, "CTGD", "GZP");
        inquiry("I5", "INQ-DEMO-105", "TRW", ss, "srm", 12000, "6.10", "USD", 75, InquiryStatus.LOST,
                "Price — buyer target FOB $6.10 vs our best $6.85", "CTGW");
        inquiry("I6", "INQ-DEMO-106", "PCB", ssNext, "jrm", 20000, "1.30", "USD", 120, InquiryStatus.HOLD, null, "ASH");
        inquiry("I7", "INQ-DEMO-107", "NVK", aw, "jrm", 9000, "4.10", "USD", 50, InquiryStatus.QUOTED, null, "GZP");
        inquiry("I8", "INQ-DEMO-108", "KST", ssNext, "srm", 15000, "7.10", "EUR", 140, null, null, "ASH", "GZP");
    }

    private void inquiry(String key, String no, String buyerKey, Long seasonId, String merchKey, int qty, String price,
                         String currency, int deliveryIn, InquiryStatus target, String lostReason, String... factoryKeys) {
        Long id = inquiryService.create(new InquiryRequest(no, buyers.get(buyerKey), seasonId, uid(merchKey), qty,
                new BigDecimal(price), currency, day(deliveryIn))).id();
        inquiries.put(key, id);
        count("Inquiries");
        int i = 0;
        for (String factoryKey : factoryKeys) {
            Long candidateId = inquiryFactoryCandidateService.create(id, new InquiryFactoryCandidateRequest(factories.get(factoryKey))).id();
            count("Inquiry factory candidates");
            if (target == InquiryStatus.WON || target == InquiryStatus.QUOTED) {
                inquiryFactoryCandidateService.updateStatus(id, candidateId, new InquiryFactoryCandidateStatusRequest(
                        i == 0 ? InquiryFactoryCandidateStatus.SELECTED : InquiryFactoryCandidateStatus.REJECTED));
            }
            i++;
        }
        if (target == null) {
            return;
        }
        switch (target) {
            case QUOTED -> status(id, InquiryStatus.QUOTED, null);
            case WON -> { status(id, InquiryStatus.QUOTED, null); status(id, InquiryStatus.WON, null); }
            case LOST -> { status(id, InquiryStatus.QUOTED, null); status(id, InquiryStatus.LOST, lostReason); }
            case HOLD -> status(id, InquiryStatus.HOLD, null);
            default -> { }
        }
    }

    private void status(Long inquiryId, InquiryStatus status, String reason) {
        inquiryService.changeStatus(inquiryId, new MarkWonLostRequest(status, reason));
    }

    // =================================================================== costing, quotation, approvals

    private void seedCostingsAndQuotations() {
        as("srm");
        // S1: v1 draft superseded by v2 (Doc 9.1), v2 approved.
        Long s1v1 = costing("S1", "I1", 30000, "2.20", items("Single jersey 165gsm", "4.20", "0.21", "0.15", "0.48", CostingComponentType.PRINTING, "0.10"));
        Long s1v2 = costingService.createRevision(s1v1, costingRequest("S1", "I1", 30000, "2.35",
                items("Single jersey 165gsm (BCI)", "4.10", "0.21", "0.15", "0.46", CostingComponentType.PRINTING, "0.10"))).id();
        count("Costing versions");
        approveCosting(s1v2, "S1", "Margin acceptable for program volume");
        // S2: approved first time.
        approveCosting(costing("S2", "I7", 9000, "4.10", items("Pique 220gsm", "4.60", "0.32", "0.35", "0.85", CostingComponentType.EMBROIDERY, "0.12")), "S2", null);
        // S3: round 1 rejected (stays DRAFT), revised to v2, approved but under the 10% margin floor.
        Long s3v1 = costing("S3", "I2", 8000, "6.80", items("Oxford 40s", "2.10", "1.65", "0.45", "1.85", CostingComponentType.WASHING, "0.20"));
        costingService.submitForApproval(s3v1);
        decide("gm", latestApproval(ApprovalTargetType.COSTING, s3v1), ApprovalStatus.REJECTED,
                "CM too high against buyer target", "CM $1.85 not acceptable — renegotiate with factory");
        as("srm");
        Long s3v2 = costingService.createRevision(s3v1, costingRequest("S3", "I2", 8000, "6.80",
                items("Oxford 40s", "2.10", "1.65", "0.45", "1.45", CostingComponentType.WASHING, "0.20"))).id();
        count("Costing versions");
        approveCosting(s3v2, "S3", "Approved below margin floor — strategic buyer");
        // S4: v1 approved, v2 (price-change rework) submitted and waiting in the inbox.
        Long s4v1 = costing("S4", null, 6000, "10.40", items("Stretch denim 11oz", "3.10", "1.30", "0.65", "1.90", CostingComponentType.WASHING, "0.85"));
        approveCosting(s4v1, "S4", null);
        as("srm");
        Long s4v2 = costingService.createRevision(s4v1, costingRequest("S4", null, 6000, "10.10",
                items("Stretch denim 11oz", "3.25", "1.30", "0.65", "1.90", CostingComponentType.WASHING, "0.95"))).id();
        count("Costing versions");
        costingService.submitForApproval(s4v2);
        count("Approvals pending");
        approveCosting(costing("S5", "I3", 6000, "10.20", items("Cotton-acrylic yarn 2/28", "6.80", "0.48", "0.20", "2.40", null, null)), "S5", null);
        // S6: first version submitted, pending.
        as("srm");
        Long s6 = costing("S6", null, 5000, "7.40", items("Viscose challis", "1.85", "1.40", "0.30", "1.70", CostingComponentType.PRINTING, "0.35"));
        costingService.submitForApproval(s6);
        count("Approvals pending");
        approveCosting(costing("S7", "I4", 10000, "10.60", items("Rigid denim 12.5oz", "3.40", "1.45", "0.80", "2.10", CostingComponentType.WASHING, "1.10")), "S7", null);
        approveCosting(costing("S8", null, 5000, "7.10", items("Fleece 300gsm", "4.90", "0.62", "0.55", "1.35", CostingComponentType.PRINTING, "0.25")), "S8", null);
        approveCosting(costing("S9", "I5", 12000, "7.60", items("Cotton twill 240gsm", "2.40", "1.55", "0.60", "1.75", CostingComponentType.WASHING, "0.30")), "S9", null);
        approveCosting(costing("S10", null, 8400, "12.10", items("Cotton-wool yarn 2/16", "7.20", "0.55", "0.45", "2.80", null, null)), "S10", null);
        approveCosting(costing("S11", "I6", 15000, "1.30", items("Single jersey 140gsm", "3.90", "0.09", "0.06", "0.28", CostingComponentType.PRINTING, "0.06")), "S11", null);
        approveCosting(costing("S12", null, 11000, "4.95", items("Cotton poplin", "1.45", "2.30", "0.25", "1.10", null, null)), "S12", null);
        // S12: a fresh draft re-costing nobody has submitted yet.
        as("srm");
        costingService.createRevision(approvedCostings.get("S12"), costingRequest("S12", null, 15000, "4.80",
                items("Cotton poplin (yarn-dyed)", "1.60", "2.30", "0.25", "1.05", null, null)));
        count("Costing versions");

        // ---- quotations (Doc 9.2), created from APPROVED costings only. QuotationService treats SENT
        // as locked (only EXPIRED may follow), so quotes that get negotiated/decided go DRAFT → NEGOTIATING.
        as("srm");
        Long q1 = quotation("S1", "NVK", "QTN-DEMO-001", 30000, "2.35", "USD", 45, 75);
        quotationService.updateStatus(q1, QuotationStatus.NEGOTIATING);
        approveQuotation(q1, ApprovalStatus.APPROVED, null);

        Long q2 = quotation("S3", "BWC", "QTN-DEMO-002", 8000, "6.95", "USD", 30, 60);
        quotationService.updateStatus(q2, QuotationStatus.NEGOTIATING);
        Long q2v2 = quotationService.createRevision(q2, quotationRequest("S3", "BWC", null, 8000, "6.80", "USD", 30, 60)).id();
        count("Quotations");
        quotationService.updateStatus(q2v2, QuotationStatus.NEGOTIATING);
        approvalService.submit(ApprovalTargetType.QUOTATION, q2v2);
        count("Approvals pending");

        Long q3 = quotation("S5", "MLM", "QTN-DEMO-003", 6000, "10.20", "EUR", 21, 90);
        approveQuotation(q3, ApprovalStatus.APPROVED, null);
        as("srm");
        Long q4 = quotation("S7", "KST", "QTN-DEMO-004", 10000, "10.60", "EUR", 14, 85);
        approveQuotation(q4, ApprovalStatus.APPROVED, null);
        as("srm");
        Long q5 = quotation("S9", "TRW", "QTN-DEMO-005", 12000, "6.85", "USD", -20, 70);
        quotationService.updateStatus(q5, QuotationStatus.NEGOTIATING);
        approveQuotation(q5, ApprovalStatus.REJECTED, "Buyer placed the program with an alternate vendor at $6.10");
        as("srm");
        Long q6 = quotation("S11", "PCB", "QTN-DEMO-006", 20000, "1.32", "USD", -10, 60);
        quotationService.updateStatus(q6, QuotationStatus.SENT);
        quotationService.updateStatus(q6, QuotationStatus.EXPIRED);
        quotation("S2", "NVK", "QTN-DEMO-007", 9000, "4.15", "USD", 30, 70);
        Long q8 = quotation("S8", "KST", "QTN-DEMO-008", 5000, "7.25", "EUR", 25, 80);
        quotationService.updateStatus(q8, QuotationStatus.SENT);
    }

    private Long costing(String styleKey, String inquiryKey, int qty, String target, List<CostingItemRequest> items) {
        as("srm");
        Long id = costingService.create(costingRequest(styleKey, inquiryKey, qty, target, items)).id();
        count("Costing versions");
        return id;
    }

    private CostingRequest costingRequest(String styleKey, String inquiryKey, int qty, String target, List<CostingItemRequest> items) {
        return new CostingRequest(styles.get(styleKey), inquiryKey != null ? inquiries.get(inquiryKey) : null, "USD",
                USD_BDT, qty, new BigDecimal(target), items);
    }

    /** Doc 9.1 cost build-up per piece: fabric (with 5% wastage), trims, CM, one value-add process and fixed overheads. */
    private List<CostingItemRequest> items(String fabric, String fabricPrice, String consumption, String trims, String cm,
                                           CostingComponentType process, String processCost) {
        List<CostingItemRequest> items = new ArrayList<>();
        items.add(item(CostingComponentType.FABRIC, fabric, fabricPrice, consumption, "5"));
        items.add(item(CostingComponentType.TRIMS, "Labels, thread, buttons/zips, hangtags", trims, "1", "2"));
        items.add(item(CostingComponentType.CM, "Cut & make", cm, "1", "0"));
        if (process != null) {
            items.add(item(process, process.name().charAt(0) + process.name().substring(1).toLowerCase(), processCost, "1", "0"));
        }
        items.add(item(CostingComponentType.PACKAGING, "Polybag, carton, tissue", "0.08", "1", "1"));
        items.add(item(CostingComponentType.TESTING, "Third-party lab tests", "0.03", "1", "0"));
        items.add(item(CostingComponentType.INSPECTION, "Final inspection (AQL 2.5)", "0.02", "1", "0"));
        items.add(item(CostingComponentType.BANK_CHARGE, "L/C and bank charges", "0.04", "1", "0"));
        items.add(item(CostingComponentType.OVERHEAD, "Buying-house overhead", "0.06", "1", "0"));
        return items;
    }

    private CostingItemRequest item(CostingComponentType type, String description, String unitCost, String consumption, String wastage) {
        return new CostingItemRequest(type, description, new BigDecimal(unitCost), new BigDecimal(consumption), new BigDecimal(wastage));
    }

    /** Submit (as merchandiser) → decide (as GM, COSTING_APPROVE) → flip the costing to APPROVED (Doc 10.2). */
    private void approveCosting(Long costingId, String styleKey, String comments) {
        as("srm");
        costingService.submitForApproval(costingId);
        decide("gm", latestApproval(ApprovalTargetType.COSTING, costingId), ApprovalStatus.APPROVED, comments, null);
        costingService.markApproved(costingId);
        approvedCostings.put(styleKey, costingId);
    }

    private Long quotation(String styleKey, String buyerKey, String no, int qty, String price, String currency, int validityIn, int leadTime) {
        as("srm");
        Long id = quotationService.create(quotationRequest(styleKey, buyerKey, no, qty, price, currency, validityIn, leadTime)).id();
        count("Quotations");
        return id;
    }

    private QuotationRequest quotationRequest(String styleKey, String buyerKey, String no, int qty, String price, String currency,
                                              int validityIn, int leadTime) {
        return new QuotationRequest(approvedCostings.get(styleKey), no, buyers.get(buyerKey), styles.get(styleKey), qty,
                new BigDecimal(price), currency, "FOB", paymentTerm("L/C 30 DAYS"), day(validityIn), leadTime);
    }

    /** Buyer's decision recorded through the approval engine, then mirrored on the quotation status. */
    private void approveQuotation(Long quotationId, ApprovalStatus decision, String rejectionReason) {
        as("srm");
        Long approvalId = approvalService.submit(ApprovalTargetType.QUOTATION, quotationId).id();
        decide("gm", approvalId, decision, decision == ApprovalStatus.APPROVED ? "Buyer confirmed by email" : null, rejectionReason);
        quotationService.updateStatus(quotationId, decision == ApprovalStatus.APPROVED ? QuotationStatus.APPROVED : QuotationStatus.REJECTED);
    }

    private Long latestApproval(ApprovalTargetType type, Long targetId) {
        return approvalService.latest(type, targetId).id();
    }

    private void decide(String userKey, Long approvalId, ApprovalStatus decision, String comments, String rejectionReason) {
        as(userKey);
        approvalService.decide(approvalId, new ApprovalDecisionRequest(decision, comments, rejectionReason));
        count("Approval decisions");
    }

    // =================================================================== sampling

    private void seedSamples() {
        as("smp");
        Long proto = sampleType("Proto Sample");
        Long fit = sampleType("Fit Sample");
        Long sizeSet = sampleType("Size Set");
        Long pp = sampleType("PP Sample");
        Long top = sampleType("TOP Sample");
        Long dev = sampleType("Development Sample");
        Long shipmentSample = sampleType("Shipment Sample");

        sample("S1", "NVK", "GZP", proto, -75, -62, rounds(-64, ApprovalStatus.APPROVED, "Fit and print placement OK"));
        sample("S1", "NVK", "GZP", fit, -60, -48,
                rounds(-52, ApprovalStatus.REJECTED, "Body length +1.5cm out of tolerance"),
                rounds(-45, ApprovalStatus.APPROVED, "Corrected length approved"));
        sample("S1", "NVK", "GZP", pp, -20, -3, rounds(-6, null, "PP sample with production trims"));
        sample("S3", "BWC", "NGJ", sizeSet, -40, -25, rounds(-28, ApprovalStatus.RETURNED, "Collar stand too stiff — comments sent, resubmit"));
        sample("S5", "MLM", "SVR", dev, -5, 10);
        sample("S7", "KST", "CTGD", pp, -70, -55, rounds(-58, ApprovalStatus.APPROVED, "Wash standard matched"));
        sample("S2", "NVK", "GZP", proto, -18, -3);
        sample("S6", "MLM", "NGJ", fit, -30, -8,
                rounds(-20, ApprovalStatus.REJECTED, "Print scale too large on front panel"),
                rounds(-7, null, "Revised print scale 80%"));
        sample("S9", "TRW", "CTGW", top, -140, -125, rounds(-128, ApprovalStatus.APPROVED, "TOP approved, release shipment"));
        sample("S11", "PCB", "ASH", shipmentSample, -12, 5, rounds(-2, null, "3 pcs per colour couriered via DHL"));
        sample("S8", "KST", "ASH", proto, -50, -38, rounds(-40, ApprovalStatus.APPROVED, null));
        sample("S12", "PCB", "CTGW", fit, -90, -78, rounds(-80, ApprovalStatus.APPROVED, "Approved with minor comments"));
    }

    private record SampleRound(int submittedOffset, ApprovalStatus decision, String comments) {
    }

    private SampleRound rounds(int submittedOffset, ApprovalStatus decision, String comments) {
        return new SampleRound(submittedOffset, decision, comments);
    }

    private void sample(String styleKey, String buyerKey, String factoryKey, Long typeId, int requestOffset, int requiredOffset,
                        SampleRound... rounds) {
        as("smp");
        Long id = sampleService.create(new SampleRequest(styles.get(styleKey), buyers.get(buyerKey), factories.get(factoryKey),
                typeId, day(requestOffset), day(requiredOffset))).id();
        sampleRepository.findById(id).ifPresent(s -> {
            s.setSampleNo(String.format("SMP-%02d-%04d", today.getYear() % 100, ++sampleSeq));
            sampleRepository.save(s);
        });
        count("Samples");
        for (SampleRound round : rounds) {
            as("smp");
            Long revisionId = sampleRevisionService.create(id, new SampleRevisionRequest(day(round.submittedOffset()), round.comments())).id();
            count("Sample revisions");
            Long approvalId = latestApproval(ApprovalTargetType.SAMPLE_REVISION, revisionId);
            if (round.decision() == null) {
                count("Approvals pending");
                continue;
            }
            decide("smp", approvalId, round.decision(), round.comments(),
                    round.decision() == ApprovalStatus.REJECTED ? round.comments() : null);
            sampleRevisionService.syncStatusFromLatestApproval(id);
        }
    }

    // =================================================================== T&A templates

    private void seedTaTemplates() {
        as("srm");
        Long standard = taTemplateService.create(new TaTemplateRequest("Standard 90-day critical path", null, null, true)).id();
        // Dependency chain (Doc A16 cascade): booking → in-house → cutting → sewing → finishing → final → packing → ex-factory.
        Map<String, String> dependsOn = Map.of(
                "Fabric Booking", "Order Confirmation",
                "Fabric In-House", "Fabric Booking",
                "PP Sample Approval", "PP Meeting",
                "Cutting", "Fabric In-House",
                "Sewing", "Cutting",
                "Finishing", "Sewing",
                "Final Inspection", "Finishing",
                "Packing", "Final Inspection",
                "Ex-Factory", "Packing");
        Map<String, Long> created = new HashMap<>();
        milestoneTypeRepository.findAll().stream()
                .sorted(Comparator.comparingInt(m -> m.getDefaultSequence()))
                .forEach(type -> {
                    String parent = dependsOn.get(type.getName());
                    Long id = taTemplateService.addMilestone(standard, new TaTemplateMilestoneRequest(type.getId(), type.getDefaultSequence(),
                            type.getTypicalOffsetDays() != null ? type.getTypicalOffsetDays() : 0,
                            parent != null ? created.get(parent) : null)).id();
                    created.put(type.getName(), id);
                });
        count("T&A templates");

        // Kestrel (denim/outdoor) skips strike-offs — a buyer-specific template wins over the default (Doc 10.3).
        Long kestrel = taTemplateService.create(new TaTemplateRequest("Kestrel Outdoor T&A (no strike-off)", buyers.get("KST"), null, false)).id();
        Map<String, Long> createdKst = new HashMap<>();
        milestoneTypeRepository.findAll().stream()
                .filter(t -> !t.getName().equals("Strike-off Approval"))
                .sorted(Comparator.comparingInt(m -> m.getDefaultSequence()))
                .forEach(type -> {
                    String parent = dependsOn.get(type.getName());
                    Long id = taTemplateService.addMilestone(kestrel, new TaTemplateMilestoneRequest(type.getId(), type.getDefaultSequence(),
                            type.getTypicalOffsetDays() != null ? type.getTypicalOffsetDays() : 0,
                            parent != null ? createdKst.get(parent) : null)).id();
                    createdKst.put(type.getName(), id);
                });
        count("T&A templates");
    }

    // =================================================================== orders and execution

    private record Line(String color, String size, int qty, String price) {
    }

    private void seedOrders() {
        // O1 — Nordvik tee, in production, on track.
        order("O1", "NVK", "PO-NVK-260145", "S1", "GZP", -80, 10, 40, "EUR", "L/C 30 DAYS", "SE", false,
                new Line("White", "S-XXL", 6000, "2.20"), new Line("Navy", "S-XXL", 6000, "2.20"));
        ta("O1", Map.of("Lab Dip Approval", 4, "Sewing", 2), Set.of(),
                "Buyer asked for a second lab dip submission (shade B)");
        inProgress("O1");
        production("O1", 25, 1, 0.55);
        inspection("O1", InspectionType.INLINE, -12, 315, InspectionResult.PASS);
        inspection("O1", InspectionType.MIDLINE, -4, 500, InspectionResult.PASS);

        // O2 — Brightwater shirt: late, FINAL inspection failed → shipment blocked by the quality gate (Doc 9.7).
        order("O2", "BWC", "PO-BWC-77810", "S3", "NGJ", -100, -5, 25, "USD", "T/T AFTER SHIPMENT", "US", false,
                new Line("Light Blue", "S-XXL", 4500, "6.80"), new Line("White", "S-XXL", 3500, "6.80"));
        ta("O2", Map.of("Fabric In-House", 6), Set.of("Final Inspection", "Packing", "Ex-Factory"),
                "Fabric mill delayed dyeing — re-run for shade");
        inProgress("O2");
        production("O2", 35, 3, 0.92);
        inspection("O2", InspectionType.INLINE, -18, 315, InspectionResult.PASS);
        Long o2mid = inspection("O2", InspectionType.MIDLINE, -10, 500, InspectionResult.FAIL);
        Long o2midDefect = defect(o2mid, "Open seam", 14, "MAJOR");
        defect(o2mid, "Skip stitch", 9, "MAJOR");
        Long capaMid = capa(o2midDefect, null, "Open seams at side seam due to worn feed dogs on line 4",
                "Replace feed dogs; 100% check of WIP", "Weekly machine maintenance log");
        capaFactoryResponse(capaMid, "Feed dogs replaced on 12 machines, WIP re-checked and repaired.");
        capaClose(capaMid);
        Long o2final = inspection("O2", InspectionType.FINAL, -4, 800, InspectionResult.FAIL);
        Long shade = defect(o2final, "Shade variation", 22, "MAJOR");
        defect(o2final, "Stain", 11, "MINOR");
        defect(o2final, "Out of tolerance", 6, "MAJOR");
        Long capaShade = capa(shade, null, "Shade variation between dye lots within cartons",
                "Re-sort by dye lot, re-pack and re-offer", "Shade band approval per lot before cutting");
        capaFactoryResponse(capaShade, "Re-sorting 3 lots by shade band; re-offer for final inspection in 3 days.");
        capa(null, o2final, "Final inspection failed AQL 2.5 — re-inspection required",
                "Full re-check of packed goods", "Pre-final internal audit by factory QA");

        // O3 — Maison Lumière sweater: fully shipped and delivered.
        order("O3", "MLM", "PO-MLM-4410", "S5", "SVR", -120, -25, 5, "EUR", "L/C AT SIGHT", "FR", false,
                new Line("Ecru", "XS-XL", 3500, "10.20"), new Line("Camel", "XS-XL", 2500, "10.20"));
        ta("O3", Map.of("Ex-Factory", 2), Set.of(), "Sweater linking capacity — 2 day slip");
        production("O3", 60, 27, 1.0);
        Long o3final = inspection("O3", InspectionType.FINAL, -26, 500, InspectionResult.PASS);
        defect(o3final, "Stain", 3, "MINOR");
        shipment("O3", "com", -23, -23, -2, 6000, 300, "Chattogram", "Le Havre", "Maersk", "MRKU4471230", ShipmentStatus.DELIVERED);

        // O4 — Kestrel denim: partially shipped (GM-authorized partial, Doc 9.9), one open packing milestone.
        order("O4", "KST", "PO-KST-90311", "S7", "CTGD", -110, -12, 20, "EUR", "L/C 30 DAYS", "DE", false,
                new Line("Dark Rinse", "28-38", 10000, "10.60"));
        ta("O4", Map.of(), Set.of("Packing", "Ex-Factory"), null);
        production("O4", 50, 14, 0.85);
        Long o4mid = inspection("O4", InspectionType.MIDLINE, -25, 500, InspectionResult.FAIL);
        Long hole = defect(o4mid, "Fabric hole", 4, "CRITICAL");
        Long capaHole = capa(hole, null, "Fabric holes traced to one roll batch", "Quarantine batch, replace panels",
                "4-point fabric inspection on receipt");
        capaFactoryResponse(capaHole, "Batch 2207 quarantined; affected panels re-cut.");
        capaClose(capaHole);
        inspection("O4", InspectionType.FINAL, -13, 800, InspectionResult.PASS);
        shipment("O4", "gm", -10, -10, 18, 6000, 500, "Chattogram", "Hamburg", "Hapag-Lloyd", "HLXU8813402", ShipmentStatus.IN_TRANSIT);

        // O5 — Thames & Rowe chino: shipped, delivered, paid and CLOSED.
        order("O5", "TRW", "PO-TRW-5520", "S9", "CTGW", -200, -120, -90, "GBP", "OPEN ACCOUNT 60 DAYS", "GB", false,
                new Line("Stone", "28-38", 4000, "6.85"), new Line("Navy", "28-38", 3500, "6.85"));
        ta("O5", Map.of("Fabric In-House", 3), Set.of(), "Twill finishing delay at mill");
        production("O5", 160, 122, 1.0);
        inspection("O5", InspectionType.FINAL, -122, 500, InspectionResult.PASS);
        shipment("O5", "com", -118, -118, -90, 7500, 375, "Chattogram", "Felixstowe", "MSC", "MSCU5523019", ShipmentStatus.DELIVERED);
        closeOrder("O5");

        // O6 — Pacific Coast kids tank: factory not yet buyer-approved → GM override with reason (Doc 9.4).
        order("O6", "PCB", "PO-PCB-11872", "S11", "ASH", -30, 60, 95, "USD", "T/T AFTER SHIPMENT", "CA", true,
                new Line("Assorted prints", "2-10Y", 15000, "1.32"));
        ta("O6", Map.of(), Set.of("Fabric Booking", "Strike-off Approval"), null);

        // O7 — Nordvik polo: early production, inline re-inspection, approvals behind.
        order("O7", "NVK", "PO-NVK-260211", "S2", "GZP", -60, 30, 60, "EUR", "L/C 30 DAYS", "SE", false,
                new Line("Black", "S-XXL", 5000, "4.10"), new Line("Bottle Green", "S-XXL", 4000, "4.10"));
        ta("O7", Map.of("Lab Dip Approval", 5), Set.of("Trim Approval", "PP Sample Approval"),
                "Embroidery thread shade rejected by buyer — resubmitted");
        inProgress("O7");
        production("O7", 8, 1, 0.10);
        Long o7inline = inspection("O7", InspectionType.INLINE, -2, 200, InspectionResult.REINSPECT);
        Long button = defect(o7inline, "Missing button", 5, "CRITICAL");
        capa(button, null, "Placket buttons missing on 5 pcs — button-attach machine skipping",
                "Service button machine; 100% placket check", "Button pull test every 2 hours");

        // O8 — Brightwater denim: cancelled by GM (ORDER_CANCEL_APPROVE, reason recorded).
        order("O8", "BWC", "PO-BWC-77954", "S4", "CTGD", -20, 75, 105, "USD", "T/T AFTER SHIPMENT", "US", false,
                new Line("Mid Indigo", "24-34", 6000, "10.40"));
        ta("O8", Map.of(), Set.of(), null);
        as("gm");
        orderService.cancel(orders.get("O8"), "Buyer cancelled the program after range review (email from M. Brooks)");
        count("Orders cancelled");

        // O9 — Maison Lumière blouse: confirmed, one approved and one pending amendment (Doc 9.4).
        order("O9", "MLM", "PO-MLM-4502", "S6", "NGJ", -45, 45, 80, "EUR", "L/C AT SIGHT", "FR", false,
                new Line("Floral AOP", "34-44", 5000, "7.40"));
        ta("O9", Map.of("Lab Dip Approval", 1), Set.of(), "Print strike-off re-done for colour");
        as("srm"); // jrm is scoped to NVK/BWC/PCB only (Doc 5.3)
        Long a1 = orderAmendmentService.request(orders.get("O9"), new OrderAmendmentRequest("exFactoryDate",
                day(52).toString(), "Viscose mill capacity — buyer agreed a 7-day extension")).id();
        as("gm");
        orderAmendmentService.decide(orders.get("O9"), a1, true);
        as("srm"); // jrm is scoped to NVK/BWC/PCB only (Doc 5.3)
        orderAmendmentService.request(orders.get("O9"), new OrderAmendmentRequest("deliveryDate",
                day(90).toString(), "Buyer requested a later DC delivery slot"));
        count("Order amendments", 2);
        as("srm"); // jrm is scoped to NVK/BWC/PCB only (Doc 5.3)
        Long a3 = orderAmendmentService.request(orders.get("O1"), new OrderAmendmentRequest("deliveryDate",
                day(32).toString(), "Buyer asked to pull delivery forward for a promotion")).id();
        as("gm");
        orderAmendmentService.decide(orders.get("O1"), a3, false);
        count("Order amendments");

        // O10 — Kestrel hoodie: shipped, vessel booked but ETD passed (at risk).
        order("O10", "KST", "PO-KST-90377", "S8", "ASH", -90, -2, 30, "EUR", "L/C 30 DAYS", "DE", false,
                new Line("Charcoal", "XS-XXL", 3000, "7.10"), new Line("Olive", "XS-XXL", 2000, "7.10"));
        ta("O10", Map.of(), Set.of(), null);
        production("O10", 35, 4, 1.0);
        inspection("O10", InspectionType.FINAL, -3, 500, InspectionResult.PASS);
        shipment("O10", "com", -1, -1, 27, 5000, 250, "Chattogram", "Rotterdam", "CMA CGM", "CMAU7710082", ShipmentStatus.BOOKED);

        // O11 — Thames & Rowe cardigan: two colourways, midline fail with CAPA in progress.
        order("O11", "TRW", "PO-TRW-5611", "S10", "SVR", -70, 20, 50, "GBP", "OPEN ACCOUNT 60 DAYS", "GB", false,
                new Line("Oatmeal", "XS-XL", 4800, "12.10"), new Line("Forest", "XS-XL", 3600, "12.10"));
        ta("O11", Map.of("PP Sample Approval", 3), Set.of(), "Wool content test report pending at lab");
        inProgress("O11");
        production("O11", 14, 1, 0.30);
        inspection("O11", InspectionType.INLINE, -6, 200, InspectionResult.PASS);
        Long o11mid = inspection("O11", InspectionType.MIDLINE, -1, 315, InspectionResult.FAIL);
        Long skip = defect(o11mid, "Skip stitch", 12, "MAJOR");
        Long capaSkip = capa(skip, null, "Linking skip stitches at shoulder", "Re-link affected pieces", "Linker operator retraining");
        capaFactoryResponse(capaSkip, "Re-linking in progress; operator training scheduled Saturday.");

        // O12 — Pacific Coast pyjama set: two shipments (partial then balance, the second delayed), fully shipped.
        order("O12", "PCB", "PO-PCB-11640", "S12", "CTGW", -150, -60, -25, "USD", "T/T AFTER SHIPMENT", "CA", false,
                new Line("Blue stripe", "XS-XL", 6000, "4.95"), new Line("Pink check", "XS-XL", 5000, "4.95"));
        ta("O12", Map.of("Ex-Factory", 4), Set.of(), "Vessel space unavailable — rolled to next feeder");
        production("O12", 95, 62, 1.0);
        Long o12final = inspection("O12", InspectionType.FINAL, -61, 500, InspectionResult.PASS);
        defect(o12final, "Stain", 4, "MINOR");
        shipment("O12", "gm", -58, -58, -30, 7000, 350, "Chattogram", "Vancouver", "ONE", "ONEU3398120", ShipmentStatus.DELIVERED);
        shipment("O12", "com", -50, -50, -18, 4000, 200, "Chattogram", "Vancouver", "ONE", "ONEU3398544", ShipmentStatus.DELAYED);

        seedDocuments();
    }

    private void order(String key, String buyerKey, String po, String styleKey, String factoryKey, int orderOffset,
                       int exFactoryIn, int deliveryIn, String currency, String paymentTerm, String country, boolean override,
                       Line... lines) {
        as(override ? "gm" : "srm");
        List<OrderItemRequest> items = new ArrayList<>();
        for (Line line : lines) {
            items.add(new OrderItemRequest(styles.get(styleKey), factories.get(factoryKey), line.color(), line.size(), line.qty(),
                    new BigDecimal(line.price())));
        }
        Long id = orderService.create(new OrderRequest(po, buyers.get(buyerKey), null, day(orderOffset), day(exFactoryIn),
                day(deliveryIn), "FOB", paymentTerm(paymentTerm), country, currency, override,
                override ? "Factory audit passed, buyer approval paperwork in progress — approved by GM to hold capacity" : null,
                items)).id();
        // Readable order numbers for the demo (the service assigns an opaque unique one).
        var order = orderRepository.findById(id).orElseThrow();
        order.setOrderNo(String.format("RMG-%02d-%04d", today.getYear() % 100, ++orderSeq));
        orderRepository.save(order);
        orders.put(key, id);
        orderFactory.put(key, factoryKey);
        count("Orders");
        count("Order items", lines.length);

        // Doc A15: generate the T&A plan for the order and assign owners per milestone.
        as("srm");
        List<Long> milestoneIds = (taMilestoneRepository.existsByOrderId(id) ? taMilestoneService.list(id) // auto-generated on confirmation (A15)
                : taMilestoneService.instantiateForOrder(id, styles.get(styleKey))).stream().map(m -> m.id()).toList();
        for (Long milestoneId : milestoneIds) {
            TaMilestone milestone = taMilestoneRepository.findById(milestoneId).orElseThrow();
            milestone.setResponsibleFactory(factoryRepository.getReferenceById(factories.get(factoryKey)));
            taMilestoneRepository.save(milestone);
            taMilestoneService.assignResponsibleUser(milestoneId, uid(ownerOf(milestone.getMilestoneType().getName(), buyerKey)));
            count("T&A milestones");
        }
    }

    private String ownerOf(String milestone, String buyerKey) {
        return switch (milestone) {
            case "Fabric In-House", "Cutting", "Sewing", "Finishing", "Packing" -> "prod";
            case "Final Inspection" -> "qa";
            case "Ex-Factory" -> "com";
            case "Lab Dip Approval", "Strike-off Approval", "Trim Approval", "PP Sample Approval" -> "smp";
            default -> Set.of("NVK", "BWC", "PCB").contains(buyerKey) ? "jrm" : "srm";
        };
    }

    /**
     * Records actual dates for every milestone already due, in date order, re-reading each
     * one first because a late completion cascades revised dates onto its dependents (A16).
     * {@code lateDays} completes those milestones late (with a reason); {@code leaveOpen}
     * leaves them uncompleted so they surface as overdue / critical delays.
     */
    private void ta(String orderKey, Map<String, Integer> lateDays, Set<String> leaveOpen, String delayReason) {
        as("prod");
        List<Long> ids = taMilestoneRepository.findByOrderIdOrderBySequence(orders.get(orderKey)).stream()
                .sorted(Comparator.comparing(TaMilestone::getPlannedDate))
                .map(TaMilestone::getId).toList();
        for (Long id : ids) {
            TaMilestone milestone = taMilestoneRepository.findById(id).orElseThrow();
            String name = milestone.getMilestoneType().getName();
            LocalDate effective = milestone.getEffectiveDate();
            if (!effective.isBefore(today) || leaveOpen.contains(name)) {
                continue;
            }
            int late = lateDays.getOrDefault(name, 0);
            LocalDate actual = effective.plusDays(late);
            if (actual.isAfter(today)) {
                actual = today;
            }
            boolean isLate = actual.isAfter(effective);
            taMilestoneService.recordActualDate(id, new RecordActualDateRequest(actual, isLate ? delayReason : null));
            count("T&A milestones completed");
        }
    }

    private void inProgress(String orderKey) {
        var order = orderRepository.findById(orders.get(orderKey)).orElseThrow();
        order.setStatus(OrderStatus.IN_PROGRESS);
        orderRepository.save(order);
    }

    private void closeOrder(String orderKey) {
        var order = orderRepository.findById(orders.get(orderKey)).orElseThrow();
        order.setStatus(OrderStatus.CLOSED);
        orderRepository.save(order);
    }

    /** Daily tallies (Doc 9.6) over a date window, skipping Fridays (BD weekend); packing ends at {@code packedFraction}. */
    private void production(String orderKey, int fromDaysAgo, int toDaysAgo, double packedFraction) {
        as("prod");
        Long orderId = orders.get(orderKey);
        int qty = orderRepository.findById(orderId).orElseThrow().getItems().stream().mapToInt(i -> i.getQuantity()).sum();
        List<LocalDate> days = new ArrayList<>();
        for (int d = fromDaysAgo; d >= toDaysAgo; d--) {
            LocalDate date = today.minusDays(d);
            if (date.getDayOfWeek() != DayOfWeek.FRIDAY) {
                days.add(date);
            }
        }
        int n = days.size();
        int packedTarget = (int) Math.floor(qty * packedFraction);
        int packedSoFar = 0;
        for (int i = 0; i < n; i++) {
            boolean last = i == n - 1;
            int packing = last ? packedTarget - packedSoFar : packedTarget / n;
            packedSoFar += packing;
            int cutting = (int) Math.round(qty * Math.min(1.03, packedFraction + 0.15) / n);
            int sewing = (int) Math.round(qty * Math.min(1.0, packedFraction + 0.08) / n);
            int finishing = (int) Math.round(qty * Math.min(1.0, packedFraction + 0.03) / n);
            int rejection = Math.max(0, sewing / 120);
            int alteration = Math.max(0, sewing / 40);
            productionUpdateService.recordDailyUpdate(orderId, new ProductionUpdateRequest(days.get(i), cutting, sewing, finishing,
                    packing, rejection, alteration));
            count("Production updates");
        }
    }

    private Long inspection(String orderKey, InspectionType type, int dateOffset, int qty, InspectionResult result) {
        as("qa");
        Long id = inspectionService.create(orders.get(orderKey), new InspectionRequest(type, day(dateOffset), qty, "2.5", result)).id();
        count("Inspections");
        return id;
    }

    private Long defect(Long inspectionId, String defectTypeName, int qty, String severity) {
        as("qa");
        Long typeId = defectTypeRepository.findAll().stream().filter(t -> t.getName().equals(defectTypeName))
                .map(t -> t.getId()).findFirst().orElseThrow();
        Long id = defectService.create(inspectionId, new DefectRequest(typeId, qty, severity, null)).id();
        count("Defects");
        return id;
    }

    private Long capa(Long defectId, Long inspectionId, String description, String corrective, String preventive) {
        as("qa");
        Long id = capaRecordService.create(new CapaRecordRequest(defectId, inspectionId, description, corrective, preventive)).id();
        count("CAPA records");
        return id;
    }

    private void capaFactoryResponse(Long capaId, String response) {
        as("fc");
        capaRecordService.recordFactoryResponse(capaId, new CapaFactoryResponseRequest(response));
    }

    private void capaClose(Long capaId) {
        as("qa");
        capaRecordService.close(capaId);
    }

    private void shipment(String orderKey, String userKey, int shipOffset, int etdOffset, int etaOffset, int qty, int cartons,
                          String pol, String pod, String line, String container, ShipmentStatus status) {
        as(userKey);
        BigDecimal gross = BigDecimal.valueOf(cartons).multiply(new BigDecimal("11.5"));
        Long id = shipmentService.create(orders.get(orderKey), new ShipmentRequest(day(shipOffset), day(etdOffset), day(etaOffset), qty,
                cartons, gross, gross.multiply(new BigDecimal("0.92")).setScale(2, RoundingMode.HALF_UP),
                BigDecimal.valueOf(cartons).multiply(new BigDecimal("0.065")).setScale(2, RoundingMode.HALF_UP),
                pol, pod, factories.get("FFW"), line, container, "BL-" + container.substring(4), false, null)).id();
        shipmentRepository.findById(id).ifPresent(s -> {
            s.setShipmentNo(String.format("SHP-%02d-%04d", today.getYear() % 100, ++shipmentSeq));
            shipmentRepository.save(s);
        });
        if (status != ShipmentStatus.BOOKED) {
            as("com");
            if (status == ShipmentStatus.DELIVERED || status == ShipmentStatus.DELAYED) {
                shipmentService.updateStatus(id, ShipmentStatus.IN_TRANSIT);
            }
            shipmentService.updateStatus(id, status);
        }
        shipments.put(orderKey + "#" + shipments.keySet().stream().filter(k -> k.startsWith(orderKey + "#")).count(), id);
        count("Shipments");
    }

    private void seedDocuments() {
        as("com");
        // Shipping document sets (Doc 9.9): invoice + packing list + B/L per shipment, approved once checked.
        for (String shipmentKey : List.of("O3#0", "O4#0", "O5#0", "O12#0", "O12#1", "O10#0")) {
            Long shipmentId = shipments.get(shipmentKey);
            boolean approve = !shipmentKey.equals("O10#0");
            document(DocumentEntityType.SHIPMENT, shipmentId, "Commercial Invoice", "Invoice-" + shipmentKey.replace('#', '-') + ".pdf", null, approve);
            document(DocumentEntityType.SHIPMENT, shipmentId, "Packing List", "PackingList-" + shipmentKey.replace('#', '-') + ".pdf", null, approve);
            if (approve) {
                document(DocumentEntityType.SHIPMENT, shipmentId, "Bill of Lading", "BL-" + shipmentKey.replace('#', '-') + ".pdf", null, true);
            }
        }
        // A corrected packing list → version 2 (FR-130: new version, never overwrite).
        document(DocumentEntityType.SHIPMENT, shipments.get("O4#0"), "Packing List", "PackingList-O4-rev2.pdf", null, false);
        // Order/style/factory documents with expiry dates — valid, expiring soon and expired.
        document(DocumentEntityType.ORDER, orders.get("O4"), "Certificate of Origin", "GSP-CO-O4.pdf", day(25), true);
        document(DocumentEntityType.ORDER, orders.get("O1"), "Inspection Certificate", "InspectionCert-O1.pdf", day(60), false);
        document(DocumentEntityType.ORDER, orders.get("O3"), "Certificate of Origin", "GSP-CO-O3.pdf", day(180), true);
        document(DocumentEntityType.STYLE, styles.get("S1"), "Test Report", "LabTest-S1-colourfastness.pdf", day(12), true);
        document(DocumentEntityType.STYLE, styles.get("S3"), "Test Report", "LabTest-S3-shrinkage.pdf", day(-8), true);
        document(DocumentEntityType.STYLE, styles.get("S10"), "Test Report", "LabTest-S10-wool-content.pdf", day(45), false);
        document(DocumentEntityType.FACTORY, factories.get("GZP"), "Test Report", "Factory-GZP-ETP-water-test.pdf", day(5), true);
        document(DocumentEntityType.FACTORY, factories.get("SVR"), "Inspection Certificate", "Factory-SVR-fire-safety.pdf", day(-20), true);
    }

    private void document(DocumentEntityType entityType, Long entityId, String typeName, String fileName, LocalDate expiry, boolean approve) {
        Long attachmentId = attach(entityType.name(), entityId, fileName, typeName, "Reference: " + fileName.replace(".pdf", ""));
        Long typeId = documentTypeRepository.findAll().stream().filter(t -> t.getName().equals(typeName))
                .map(t -> t.getId()).findFirst().orElseThrow();
        Long id = commercialDocumentService.upload(new CommercialDocumentRequest(entityType, entityId, typeId, attachmentId, expiry)).id();
        if (approve) {
            commercialDocumentService.approve(id);
        }
        count("Commercial documents");
    }

    private Long attach(String entityType, Long entityId, String fileName, String title, String body) {
        Long id = attachmentService.upload(entityType, entityId, new DemoFile(fileName, "application/pdf", pdf(title, body))).id();
        count("Attachments");
        return id;
    }

    // =================================================================== finance and claims

    private void seedFinancials() {
        as("acc");
        financials("O1", "2.20", "1.93", null);
        financials("O2", "6.80", "6.21", null);
        financials("O3", "10.20", "8.71", "10.20");
        financials("O4", "10.60", "8.98", "10.45");
        financials("O5", "6.85", "6.08", "6.70");
        financials("O6", "1.32", "1.12", null);
        financials("O7", "4.10", "3.58", null);
        financials("O9", "7.40", "6.62", null);
        financials("O10", "7.10", "6.18", "7.10");
        financials("O11", "12.10", "10.42", null);
        financials("O12", "4.95", "4.61", "4.80");

        // Receivables from buyers — received, partial-overdue, overdue, pending.
        Long r1 = receivable("O1", "NVK", "5280.00", "EUR", -40);
        pay(r1, null, "5280.00", -41, "TT", "NVK-ADV-2201");
        Long r3 = receivable("O3", "MLM", "61200.00", "EUR", -10);
        pay(r3, null, "36720.00", -12, "LC", "LC-MLM-4410-01");
        receivable("O4", "KST", "62700.00", "EUR", 20);
        Long r5 = receivable("O5", "TRW", "50250.00", "GBP", -60);
        pay(r5, null, "50250.00", -62, "TT", "TRW-INV-5520");
        receivable("O10", "KST", "35500.00", "EUR", 30);
        Long r12a = receivable("O12", "PCB", "33600.00", "USD", -28);
        pay(r12a, null, "33600.00", -27, "TT", "PCB-11640-A");
        receivable("O12", "PCB", "19200.00", "USD", -5);

        // Payables to factories — paid, partial-overdue, partial, pending.
        Long p1 = payable("O1", "GZP", "4600.00", "USD", -15);
        pay(null, p1, "4600.00", -16, "TT", "ADV-GZP-O1");
        Long p3 = payable("O3", "SVR", "14400.00", "USD", -5);
        pay(null, p3, "8000.00", -8, "TT", "SVR-CM-4410");
        payable("O4", "CTGD", "21000.00", "USD", 15);
        Long p5 = payable("O5", "CTGW", "13125.00", "USD", -70);
        pay(null, p5, "13125.00", -72, "TT", "CTGW-CM-5520");
        Long p12 = payable("O12", "CTGW", "12100.00", "USD", 10);
        pay(null, p12, "6000.00", -20, "TT", "CTGW-CM-11640");
        payable("O10", "ASH", "7500.00", "USD", 25);
    }

    private void financials(String orderKey, String quoted, String actualCost, String realized) {
        orderFinancialsService.upsert(orders.get(orderKey), new OrderFinancialsRequest(new BigDecimal(quoted), new BigDecimal(actualCost),
                realized != null ? new BigDecimal(realized) : null));
        count("Order financials");
    }

    private Long receivable(String orderKey, String buyerKey, String amount, String currency, int dueIn) {
        Long id = receivableService.create(orders.get(orderKey), new ReceivableRequest(buyers.get(buyerKey), new BigDecimal(amount),
                currency, day(dueIn))).id();
        count("Receivables");
        return id;
    }

    private Long payable(String orderKey, String factoryKey, String amount, String currency, int dueIn) {
        Long id = payableService.create(orders.get(orderKey), new PayableRequest(factories.get(factoryKey), new BigDecimal(amount),
                currency, day(dueIn))).id();
        count("Payables");
        return id;
    }

    private void pay(Long receivableId, Long payableId, String amount, int paidOffset, String method, String reference) {
        paymentRecordService.record(new PaymentRecordRequest(receivableId, payableId, new BigDecimal(amount), day(paidOffset), method, reference));
        count("Payments");
    }

    private void seedClaims() {
        as("com");
        claim("O4", shipments.get("O4#0"), ClaimRaisedBy.BUYER, ClaimType.SHORT_SHIPMENT,
                "Buyer reports 120 pcs short against packing list on carton 212-240", "3200.00", null, null);
        claim("O12", shipments.get("O12#1"), ClaimRaisedBy.BUYER, ClaimType.QUALITY,
                "Shade variation complaints from 3 stores on Pink check colourway", "5400.00", ClaimStatus.UNDER_REVIEW,
                "Counter-samples requested from buyer DC; factory lab comparing against approved shade band");
        claim("O5", shipments.get("O5#0"), ClaimRaisedBy.BUYER, ClaimType.DELAY,
                "Late delivery penalty — arrived 4 days after DC slot", "1500.00", ClaimStatus.RESOLVED,
                "Settled: 2% discount agreed on next Thames & Rowe order");
        claim("O3", shipments.get("O3#0"), ClaimRaisedBy.BUYER, ClaimType.OTHER,
                "Carton side marks not in buyer format", "800.00", ClaimStatus.REJECTED,
                "Rejected — markings match the buyer-approved shipping mark spec v3");
        claim("O2", null, ClaimRaisedBy.INTERNAL, ClaimType.QUALITY,
                "Internal claim against factory for re-inspection cost after FINAL fail", "450.00", null, null);
    }

    private void claim(String orderKey, Long shipmentId, ClaimRaisedBy raisedBy, ClaimType type, String description, String amount,
                       ClaimStatus outcome, String resolution) {
        as("com");
        Long id = claimService.create(orders.get(orderKey), new ClaimRequest(shipmentId, raisedBy, type, description,
                amount != null ? new BigDecimal(amount) : null)).id();
        count("Claims");
        if (outcome != null) {
            as("acc");
            if (outcome != ClaimStatus.UNDER_REVIEW) {
                claimService.resolve(id, new ClaimResolutionRequest(ClaimStatus.UNDER_REVIEW, "Investigating"));
            }
            claimService.resolve(id, new ClaimResolutionRequest(outcome, resolution));
        }
    }

    // =================================================================== communication, tasks, notifications

    private void seedCommunication() {
        activity("srm", "Buyer", buyers.get("NVK"), ActivityType.MEETING, -6,
                "Quarterly review with Elin (Nordvik) — SS27 volumes up 15%, wants more BCI cotton styles.");
        activity("jrm", "Buyer", buyers.get("BWC"), ActivityType.EMAIL, -2,
                "Sent re-inspection plan for PO-BWC-77810 after FINAL fail; buyer accepts 5-day slip.");
        activity("srm", "Buyer", buyers.get("KST"), ActivityType.CALL, -1,
                "Jonas confirmed partial shipment acceptance; balance to follow by sea.");
        activity("gm", "Buyer", buyers.get("PCB"), ActivityType.NOTE, -3,
                "Ashulia factory approval for PCB still pending — override used for O6, chase audit report.");
        activity("srm", "Order", orders.get("O2"), ActivityType.MEETING, -3,
                "Factory meeting at Narayanganj: shade sorting plan agreed, re-offer date set.");
        activity("prod", "Order", orders.get("O1"), ActivityType.NOTE, 0,
                "Line 6 & 7 running at 92% efficiency; packing started today.");
        activity("prod", "Order", orders.get("O7"), ActivityType.CALL, -1,
                "Embroidery thread re-dyed; trims arrive Sunday.");
        activity("com", "Order", orders.get("O4"), ActivityType.EMAIL, -9,
                "Shipping docs for first lot sent to Kestrel and bank.");
        activity("acc", "Order", orders.get("O3"), ActivityType.CALL, -4,
                "Reminded Maison Lumiere's bank about the outstanding L/C balance.");
        activity("jrm", "Inquiry", inquiries.get("I1"), ActivityType.EMAIL, -5,
                "Received SS27 tech packs and target prices from Nordvik.");
        activity("srm", "Inquiry", inquiries.get("I8"), ActivityType.MEETING, -2,
                "Kick-off with Kestrel for SS27 fleece capsule.");
        activity("smp", "Style", styles.get("S1"), ActivityType.NOTE, -6,
                "PP sample couriered via DHL (AWB 7731 2209 11).");
        activity("smp", "Style", styles.get("S6"), ActivityType.EMAIL, -7,
                "Resubmitted fit sample with print scaled to 80%.");
        activity("fc", "Factory", factories.get("GZP"), ActivityType.MEETING, -8,
                "Monthly compliance walk-through; BSCI renewal audit to be booked.");
        activity("qa", "Factory", factories.get("NGJ"), ActivityType.NOTE, -4,
                "Raised shade-band discipline with factory QA head.");

        task("gm", "jrm", "Order", orders.get("O2"), "Arrange re-inspection for PO-BWC-77810", TaskPriority.URGENT, -1, TaskStatus.OPEN);
        task("gm", "qa", "Order", orders.get("O2"), "Witness shade re-sorting at Narayanganj", TaskPriority.HIGH, 0, TaskStatus.IN_PROGRESS);
        task("srm", "smp", "Style", styles.get("S2"), "Chase proto sample for NVK pique polo", TaskPriority.HIGH, -3, TaskStatus.OPEN);
        task("srm", "prod", "Order", orders.get("O7"), "Confirm trims in-house date for PO-NVK-260211", TaskPriority.MEDIUM, 2, TaskStatus.OPEN);
        task("srm", "com", "Order", orders.get("O10"), "Re-book vessel for PO-KST-90377 (ETD missed)", TaskPriority.URGENT, -1, TaskStatus.OPEN);
        task("gm", "acc", "Order", orders.get("O3"), "Follow up L/C balance with Maison Lumiere", TaskPriority.HIGH, -2, TaskStatus.OPEN);
        task("gm", "acc", "Order", orders.get("O12"), "Collect balance payment from Pacific Coast", TaskPriority.MEDIUM, 3, TaskStatus.OPEN);
        task("srm", "jrm", "Inquiry", inquiries.get("I1"), "Prepare costing for NVK SS27 tee program", TaskPriority.MEDIUM, 5, TaskStatus.IN_PROGRESS);
        task("gm", "srm", "Buyer", buyers.get("PCB"), "Close factory approval for Ashulia (PCB)", TaskPriority.HIGH, -4, TaskStatus.OPEN);
        task("gm", "fc", "Factory", factories.get("GZP"), "Book BSCI renewal audit for Gazipur Knit", TaskPriority.MEDIUM, 7, TaskStatus.OPEN);
        task("qa", "fc", "Order", orders.get("O1"), "Share inline inspection photos with factory", TaskPriority.LOW, 1, TaskStatus.OPEN);
        task("srm", "smp", "Style", styles.get("S6"), "Get decision on resubmitted blouse fit sample", TaskPriority.MEDIUM, 0, TaskStatus.OPEN);
        task("gm", "srm", "Order", orders.get("O9"), "Decide on DC slot change request (PO-MLM-4502)", TaskPriority.HIGH, 1, TaskStatus.OPEN);
        task("srm", "jrm", "Order", orders.get("O1"), "Send packing instructions to Gazipur", TaskPriority.LOW, -5, TaskStatus.DONE);
        task("gm", "owner", "Buyer", buyers.get("NVK"), "Review Nordvik SS27 volume commitment", TaskPriority.MEDIUM, 4, TaskStatus.OPEN);
        task("gm", "admin", "Buyer", buyers.get("TRW"), "Set up new Thames & Rowe user accounts", TaskPriority.LOW, 2, TaskStatus.OPEN);

        notify("gm", "Order", orders.get("O2"), "FINAL inspection FAILED for RMG order PO-BWC-77810 — shipment blocked");
        notify("srm", "Order", orders.get("O2"), "FINAL inspection FAILED for PO-BWC-77810 — re-inspection needed");
        notify("owner", "Order", orders.get("O8"), "Order PO-BWC-77954 was cancelled by the General Manager");
        notify("gm", "Costing", approvedCostings.get("S3"), "Costing for BWC-SS26-SH310 approved below the 10% margin floor");
        notify("srm", "Inquiry", inquiries.get("I5"), "Quotation QTN-DEMO-005 rejected by Thames & Rowe — inquiry marked LOST");
        notify("acc", "Order", orders.get("O3"), "Receivable for PO-MLM-4410 is overdue (partially received)");
        notify("acc", "Order", orders.get("O12"), "Receivable for PO-PCB-11640 balance is overdue");
        notify("com", "Order", orders.get("O10"), "Shipment for PO-KST-90377 missed its ETD — re-book vessel");
        notify("qa", "Order", orders.get("O7"), "Inline re-inspection due for PO-NVK-260211");
        notify("smp", "Style", styles.get("S2"), "Proto sample for NVK-AW26-PL204 is overdue");
        notify("fc", "Factory", factories.get("GZP"), "BSCI certificate for Gazipur Knit expires in 20 days");
        notify("view", "Order", orders.get("O4"), "PO-KST-90311 partially shipped (6,000 of 10,000 pcs)");
        notify("jrm", "Order", orders.get("O9"), "Your ex-factory amendment for PO-MLM-4502 was approved");
        notify("admin", "Buyer", buyers.get("TRW"), "Demo data loaded — log in as any role with password " + DEMO_PASSWORD);
        // A couple already read, so the read/unread states both show.
        for (String userKey : List.of("gm", "srm")) {
            as(userKey);
            notificationRepository.findByUser_IdOrderByCreatedAtDesc(uid(userKey)).stream().reduce((first, second) -> second)
                    .ifPresent(n -> notificationService.markRead(n.getId()));
        }
    }

    private void activity(String userKey, String entityType, Long entityId, ActivityType type, int dayOffset, String content) {
        as(userKey);
        activityService.log(new ActivityRequest(entityType, entityId, type,
                day(dayOffset).atTime(dayOffset == 0 ? LocalTime.of(9, 15) : LocalTime.of(11, 30)).atZone(DHAKA).toInstant(), content));
        count("Activities");
    }

    private void task(String creatorKey, String assigneeKey, String entityType, Long entityId, String title, TaskPriority priority,
                      int dueIn, TaskStatus status) {
        as(creatorKey);
        Long id = taskItemService.create(new TaskRequest(entityType, entityId, title, null, uid(assigneeKey), priority, day(dueIn))).id();
        if (status != TaskStatus.OPEN) {
            taskItemService.updateStatus(id, status);
        }
        count("Tasks");
    }

    private void notify(String userKey, String entityType, Long entityId, String message) {
        notificationService.notify(uid(userKey), entityType, entityId, message);
        count("Notifications");
    }

    /** Same message the 07:00 overdue scan (Doc 13 A2) would send — limited to demo milestones so real users aren't spammed. */
    private void seedOverdueMilestoneNotifications() {
        for (Long orderId : orders.values()) {
            for (TaMilestone milestone : taMilestoneRepository.findByOrderIdOrderBySequence(orderId)) {
                var order = milestone.getOrder();
                if (milestone.getActualDate() == null && milestone.getEffectiveDate().isBefore(today)
                        && milestone.getResponsibleUser() != null
                        && order.getStatus() != OrderStatus.CANCELLED && order.getStatus() != OrderStatus.CLOSED) {
                    notificationService.notify(milestone.getResponsibleUser().getId(), "TaMilestone", milestone.getId(),
                            "T&A milestone '" + milestone.getMilestoneType().getName() + "' for order " + order.getOrderNo()
                                    + " is overdue (was due " + milestone.getEffectiveDate() + ")");
                    count("Notifications");
                }
            }
        }
    }

    // =================================================================== helpers

    private LocalDate day(int offsetFromToday) {
        return today.plusDays(offsetFromToday);
    }

    private Long paymentTerm(String name) {
        return paymentTermRepository.findAll().stream().filter(t -> t.getName().equals(name))
                .map(t -> t.getId()).findFirst().orElse(null);
    }

    private Long sampleType(String name) {
        Map<String, Long> byName = sampleTypeRepository.findAll().stream()
                .collect(Collectors.toMap(t -> t.getName(), t -> t.getId(), (a, b) -> a));
        return byName.get(name);
    }

    private void count(String module) {
        count(module, 1);
    }

    private void count(String module, int n) {
        counts.merge(module, n, Integer::sum);
    }

    private static byte[] pdf(String title, String body) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        com.lowagie.text.Document document = new com.lowagie.text.Document(PageSize.A4);
        PdfWriter.getInstance(document, out);
        document.open();
        document.add(new Paragraph(title, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16)));
        document.add(new Paragraph("RMGFlow demo document — generated sample content, not a real record.",
                FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 9)));
        document.add(new Paragraph(" "));
        document.add(new Paragraph(body, FontFactory.getFont(FontFactory.HELVETICA, 11)));
        document.close();
        return out.toByteArray();
    }

    /** Minimal in-memory MultipartFile so demo files go through the real AttachmentService/StorageService path. */
    private record DemoFile(String fileName, String type, byte[] bytes) implements MultipartFile {
        @Override public String getName() { return "file"; }
        @Override public String getOriginalFilename() { return fileName; }
        @Override public String getContentType() { return type; }
        @Override public boolean isEmpty() { return bytes.length == 0; }
        @Override public long getSize() { return bytes.length; }
        @Override public byte[] getBytes() { return bytes; }
        @Override public InputStream getInputStream() { return new ByteArrayInputStream(bytes); }
        @Override public void transferTo(File dest) throws IOException { Files.write(dest.toPath(), bytes); }
        @Override public void transferTo(Path dest) throws IOException { Files.write(dest, bytes); }
    }
}
