package com.rmgflow.masterdata.controller;

import com.rmgflow.masterdata.entity.*;
import com.rmgflow.masterdata.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Document 21 P2-T1: read access open to any authenticated user (every
 * feature needs these for dropdowns); writes restricted to MASTER_DATA_MANAGE
 * (Doc 5.2). Currencies/countries/incoterms are ISO-code-shaped reference
 * tables maintained via migration rather than a write endpoint in v1 — the
 * set changes rarely enough that a migration is simpler than building and
 * securing six more CRUD endpoints for it (Doc 56 rule 7: no unnecessary
 * machinery). Payment terms / document types / defect types / milestone
 * types are genuinely organization-configurable, so those get write endpoints.
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ReferenceDataController {

    private final CurrencyRepository currencyRepository;
    private final CountryRepository countryRepository;
    private final IncotermRepository incotermRepository;
    private final PaymentTermRepository paymentTermRepository;
    private final DocumentTypeRepository documentTypeRepository;
    private final DefectTypeRepository defectTypeRepository;
    private final MilestoneTypeRepository milestoneTypeRepository;
    private final SeasonRepository seasonRepository;

    @GetMapping("/currencies")
    public List<Currency> currencies() {
        return currencyRepository.findAll();
    }

    @GetMapping("/countries")
    public List<Country> countries() {
        return countryRepository.findAll();
    }

    @GetMapping("/incoterms")
    public List<Incoterm> incoterms() {
        return incotermRepository.findAll();
    }

    @GetMapping("/payment-terms")
    public List<PaymentTerm> paymentTerms() {
        return paymentTermRepository.findAll();
    }

    @PostMapping("/payment-terms")
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    public PaymentTerm createPaymentTerm(@RequestBody PaymentTerm paymentTerm) {
        paymentTerm.setId(null);
        return paymentTermRepository.save(paymentTerm);
    }

    @GetMapping("/document-types")
    public List<DocumentType> documentTypes() {
        return documentTypeRepository.findAll();
    }

    @PostMapping("/document-types")
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    public DocumentType createDocumentType(@RequestBody DocumentType documentType) {
        documentType.setId(null);
        return documentTypeRepository.save(documentType);
    }

    @GetMapping("/defect-types")
    public List<DefectType> defectTypes() {
        return defectTypeRepository.findAll();
    }

    @PostMapping("/defect-types")
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    public DefectType createDefectType(@RequestBody DefectType defectType) {
        defectType.setId(null);
        return defectTypeRepository.save(defectType);
    }

    @GetMapping("/milestone-types")
    public List<MilestoneType> milestoneTypes() {
        return milestoneTypeRepository.findAll();
    }

    @PostMapping("/milestone-types")
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    public MilestoneType createMilestoneType(@RequestBody MilestoneType milestoneType) {
        milestoneType.setId(null);
        return milestoneTypeRepository.save(milestoneType);
    }

    @GetMapping("/seasons")
    public List<Season> seasons() {
        return seasonRepository.findAll();
    }

    @PostMapping("/seasons")
    @PreAuthorize("hasAuthority('MASTER_DATA_MANAGE')")
    public Season createSeason(@RequestBody Season season) {
        season.setId(null);
        return seasonRepository.save(season);
    }
}
