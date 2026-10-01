package com.rmgflow.masterdata.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "currencies")
@Getter
@Setter
@NoArgsConstructor
public class Currency {

    @Id
    @Column(length = 3)
    private String code;

    @Column(nullable = false)
    private String name;
}
