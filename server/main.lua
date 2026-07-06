local T = require("server.constants")

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        identifier        VARCHAR(60) PRIMARY KEY,
        name              VARCHAR(50),
        level             INT         DEFAULT 1,
        xp                INT         DEFAULT 0,
        skill_points      INT         DEFAULT 3,
        skills            JSON        DEFAULT '[]',
        total_earnings    BIGINT      DEFAULT 0,
        total_deliveries  INT         DEFAULT 0,
        failed_deliveries INT         DEFAULT 0,
        equipped_vehicle  VARCHAR(50) DEFAULT NULL,
        created_at        TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
        updated_at        TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]]):format(T.players))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id            INT AUTO_INCREMENT PRIMARY KEY,
        identifier    VARCHAR(60),
        vehicle_slot  VARCHAR(50),
        vehicle_model VARCHAR(50),
        purchased_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_player_vehicle (identifier, vehicle_slot)
    )]]):format(T.vehicles))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id            INT AUTO_INCREMENT PRIMARY KEY,
        identifier    VARCHAR(60),
        trailer_slot  VARCHAR(50),
        trailer_model VARCHAR(50),
        purchased_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_player_trailer (identifier, trailer_slot)
    )]]):format(T.trailers))

    MySQL.query.await(([[ALTER TABLE %s ADD COLUMN IF NOT EXISTS equipped_trailer VARCHAR(50) DEFAULT NULL]]):format(T.players))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id                   VARCHAR(36)  PRIMARY KEY,
        name                 VARCHAR(100),
        cargo                VARCHAR(50),
        cargo_type           ENUM('standard','fragile','hazmat','heavy','live','valuable') DEFAULT 'standard',
        weight_kg            INT,
        distance_km          FLOAT,
        reward_base          INT,
        xp_base              INT,
        time_minutes         INT,
        pickup_label         VARCHAR(100),
        pickup_city          VARCHAR(50),
        pickup_x             FLOAT, pickup_y FLOAT, pickup_z FLOAT,
        dropoff_label        VARCHAR(100),
        dropoff_city         VARCHAR(50),
        dropoff_x            FLOAT, dropoff_y FLOAT, dropoff_z FLOAT,
        comment              TEXT,
        tag                  VARCHAR(30),
        tag_color            VARCHAR(20),
        tag_bg               VARCHAR(40),
        icon                 VARCHAR(60),
        level_required       INT        DEFAULT 1,
        requires_hazmat      TINYINT(1) DEFAULT 0,
        requires_long_hauler TINYINT(1) DEFAULT 0,
        is_active            TINYINT(1) DEFAULT 1
    )]]):format(T.orders))

    MySQL.query.await(([[ALTER TABLE %s ADD COLUMN IF NOT EXISTS pickup_heading  FLOAT DEFAULT 0]]):format(T.orders))
    MySQL.query.await(([[ALTER TABLE %s ADD COLUMN IF NOT EXISTS dropoff_heading FLOAT DEFAULT 0]]):format(T.orders))
    MySQL.query.await(([[ALTER TABLE %s ADD COLUMN IF NOT EXISTS pickup_pallet_coords JSON DEFAULT NULL]]):format(T.orders))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id           INT AUTO_INCREMENT PRIMARY KEY,
        order_id     VARCHAR(36),
        identifier   VARCHAR(60),
        status       ENUM('active','completed','failed','abandoned') DEFAULT 'active',
        reward_paid  INT       DEFAULT 0,
        xp_paid      INT       DEFAULT 0,
        started_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP NULL
    )]]):format(T.deliveries))

    MySQL.query.await(([[ALTER TABLE %s MODIFY COLUMN status ENUM('active','completed','failed','abandoned') DEFAULT 'active']]):format(T.deliveries))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id               INT AUTO_INCREMENT PRIMARY KEY,
        name             VARCHAR(100) UNIQUE,
        tag              VARCHAR(10),
        description      TEXT,
        level            INT    DEFAULT 1,
        xp               INT    DEFAULT 0,
        treasury         BIGINT DEFAULT 0,
        total_earnings   BIGINT DEFAULT 0,
        total_deliveries INT    DEFAULT 0,
        open_recruitment TINYINT(1) DEFAULT 0,
        founded_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]]):format(T.companies))

    MySQL.query.await(([[ALTER TABLE %s ADD COLUMN IF NOT EXISTS tax_rate TINYINT UNSIGNED DEFAULT 0]]):format(T.companies))
    MySQL.query.await(([[ALTER TABLE %s ADD COLUMN IF NOT EXISTS min_level_to_join TINYINT UNSIGNED DEFAULT 1]]):format(T.companies))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id         INT AUTO_INCREMENT PRIMARY KEY,
        company_id INT,
        identifier VARCHAR(60),
        role       ENUM('owner','manager','driver','recruit') DEFAULT 'recruit',
        deliveries INT    DEFAULT 0,
        earnings   BIGINT DEFAULT 0,
        joined_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_member (identifier)
    )]]):format(T.members))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id                INT AUTO_INCREMENT PRIMARY KEY,
        company_id        INT,
        target_identifier VARCHAR(60),
        invited_by        VARCHAR(60),
        created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_invite (company_id, target_identifier)
    )]]):format(T.invitations))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        company_id  INT,
        label       VARCHAR(200),
        amount      INT,
        is_positive TINYINT(1),
        icon        VARCHAR(60),
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )]]):format(T.transactions))

    print("[polarix_trucker] Schema initialisiert.")

    LoadDatabaseToCache()
    Orders.SeedIfEmpty()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
end)
