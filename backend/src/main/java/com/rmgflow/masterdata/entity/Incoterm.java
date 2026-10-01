package com.rmgflow.masterdata.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "incoterms")
@Getter
@Setter
@NoArgsConstructor
public class Incoterm {

    @Id
    @Column(length = 3)
    private String code;

    @Column(nullable = false)
    private String name;
}
