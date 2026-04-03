-- Auto-generated from Prisma schemas of all services.
-- Postgres runs this on first DB init (/docker-entrypoint-initdb.d/).

-- ════════════════════════════════════════════════════════════════
-- auth-service
-- ════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS "users" (
    "id"         TEXT        NOT NULL,
    "email"      TEXT        NOT NULL,
    "password"   TEXT        NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "users_email_key" ON "users"("email");

CREATE TABLE IF NOT EXISTS "user_notification_settings" (
    "id"                TEXT        NOT NULL,
    "userId"            TEXT        NOT NULL,
    "telegramEnabled"   BOOLEAN     NOT NULL DEFAULT false,
    "telegramChatId"    TEXT,
    "emailEnabled"      BOOLEAN     NOT NULL DEFAULT false,
    "created_at"        TIMESTAMPTZ NOT NULL DEFAULT now(),
    "updated_at"        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT "user_notification_settings_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "user_notification_settings_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "user_notification_settings_userId_key" ON "user_notification_settings"("userId");

-- ════════════════════════════════════════════════════════════════
-- camera-service
-- ════════════════════════════════════════════════════════════════

DO $$
BEGIN
    CREATE TYPE "Status" AS ENUM ('ON', 'OFF');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "locations" (
    "id"      TEXT NOT NULL,
    "name"    TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    CONSTRAINT "locations_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "locations_user_id_name_key" ON "locations"("user_id", "name");

CREATE TABLE IF NOT EXISTS "cameras" (
    "id"          TEXT NOT NULL,
    "name"        TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    CONSTRAINT "cameras_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "cameras_location_id_fkey"
        FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "camera_settings" (
    "id"               TEXT     NOT NULL,
    "ai_status"        "Status" NOT NULL DEFAULT 'OFF',
    "recording_status" "Status" NOT NULL DEFAULT 'OFF',
    "camera_id"        TEXT     NOT NULL,
    CONSTRAINT "camera_settings_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "camera_settings_camera_id_fkey"
        FOREIGN KEY ("camera_id") REFERENCES "cameras"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "camera_settings_camera_id_key" ON "camera_settings"("camera_id");

-- ════════════════════════════════════════════════════════════════
-- events-service
-- ════════════════════════════════════════════════════════════════

DO $$
BEGIN
    CREATE TYPE "EventType" AS ENUM (
        'CAMERA_JOIN', 'CAMERA_LEAVE',
        'START_RECORDING', 'STOP_RECORDING',
        'MOTION_DETECTED', 'MOTION_ON', 'MOTION_OFF'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "events" (
    "id"         TEXT        NOT NULL,
    "camera_id"  TEXT        NOT NULL,
    "user_id"    TEXT        NOT NULL,
    "event_type" "EventType" NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT "events_pkey" PRIMARY KEY ("id")
);

-- ════════════════════════════════════════════════════════════════
-- video-service
-- ════════════════════════════════════════════════════════════════

DO $$
BEGIN
    CREATE TYPE "VideoFileStatus" AS ENUM ('RECORDING', 'FINISHED');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "Egress" (
    "id"       TEXT NOT NULL,
    "roomId"   TEXT NOT NULL,
    "egressId" TEXT NOT NULL,
    CONSTRAINT "Egress_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Egress_roomId_key" ON "Egress"("roomId");

CREATE TABLE IF NOT EXISTS "VideoFile" (
    "id"           TEXT              NOT NULL,
    "cameraId"     TEXT              NOT NULL,
    "playlistName" TEXT              NOT NULL,
    "status"       "VideoFileStatus" NOT NULL DEFAULT 'RECORDING',
    "createdAt"    TIMESTAMPTZ       NOT NULL DEFAULT now(),
    "updatedAt"    TIMESTAMPTZ       NOT NULL DEFAULT now(),
    "finishedAt"   TIMESTAMPTZ,
    CONSTRAINT "VideoFile_pkey" PRIMARY KEY ("id")
);
