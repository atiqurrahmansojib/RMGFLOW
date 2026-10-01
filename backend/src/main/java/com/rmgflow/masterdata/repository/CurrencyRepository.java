package com.rmgflow.masterdata.repository;

import com.rmgflow.masterdata.entity.Currency;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CurrencyRepository extends JpaRepository<Currency, String> {
}
